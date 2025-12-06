#!/bin/bash

cmd_verify() {
    local interactive_mode=false
    if [[ "$1" == "--interactive" ]]; then
        interactive_mode=true
    fi

    print_info "Verifying PATH configuration..."
    ensure_path_file_structure

    # --- Manage orphaned paths ---
    local existing_paths=()
    local orphaned_paths=()
    local temp_path_file=$(mktemp)

    # Read existing paths and identify orphans
    if [ -f "$UBREW_PATH_FILE" ]; then
        # Use a subshell to avoid variable scope issues with the while loop
        {
            read -r -d '' managed_paths_block
            # Process only the lines within the managed block
            while IFS= read -r line; do
                [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
                
                local pkg_name
                pkg_name=$(echo "$line" | sed -n 's/.*# ubrew: \(.*\)$/\1/p')

                if [ -d "$LOCAL_PACKAGES/$pkg_name" ]; then
                    existing_paths+=("$pkg_name")
                    echo "$line" >> "$temp_path_file"
                else
                    orphaned_paths+=("$pkg_name")
                fi
            done <<< "$managed_paths_block"
        } < <(sed -n '/^# === BEGIN UBREW MANAGED PATHS ===$/,/^# === END UBREW MANAGED PATHS ===$/p' "$UBREW_PATH_FILE" | sed '1d;$d')
    fi

    # Report and handle orphaned paths
    if [ ${#orphaned_paths[@]} -gt 0 ]; then
        for orphan in "${orphaned_paths[@]}"; do
            print_warning "Orphaned PATH entry removed: $orphan"
        done
    fi

    # --- Add missing package paths ---
    local added_packages=()
    if [ -d "$LOCAL_PACKAGES" ]; then
        for pkg_dir in "$LOCAL_PACKAGES"/*; do
            if [ -d "$pkg_dir" ]; then
                local pkg_name=$(basename "$pkg_dir")
                local is_existing=false
                for existing in "${existing_paths[@]}"; do
                    if [[ "$existing" == "$pkg_name" ]]; then
                        is_existing=true
                        break
                    fi
                done

                if ! $is_existing; then
                    local bin_dir
                    if [ -d "$pkg_dir/bin" ]; then
                        bin_dir="$pkg_dir/bin"
                    elif [ -d "$pkg_dir/target" ]; then
                        bin_dir="$pkg_dir/target"
                    else
                        bin_dir="$pkg_dir"
                    fi
                    echo "export PATH=\"$bin_dir:\$PATH\" # ubrew: $pkg_name" >> "$temp_path_file"
                    added_packages+=("$pkg_name")
                fi
            fi
        done
    fi

    # Report newly added packages
    if [ ${#added_packages[@]} -gt 0 ]; then
        for added in "${added_packages[@]}"; do
            print_success "Added missing PATH entry: $added"
        done
    fi

    # --- Rewrite the UBREW_PATH_FILE ---
    local before_marker
    local after_marker
    before_marker=$(sed '/^# === BEGIN UBREW MANAGED PATHS ===$/q' "$UBREW_PATH_FILE")
    after_marker=$(sed '1,/^# === END UBREW MANAGED PATHS ===$/d' "$UBREW_PATH_FILE")

    {
        echo "$before_marker"
        if [ -s "$temp_path_file" ]; then
            cat "$temp_path_file"
        fi
        echo "$after_marker"
    } > "$UBREW_PATH_FILE"
    rm -f "$temp_path_file"

    # --- Check for orphaned archives ---
    if [ -d "$UBREW_ROOT/archives" ]; then
        for archive in "$UBREW_ROOT/archives"/*; do
            [ -f "$archive" ] || continue
            local pkg_name
            pkg_name=$(infer_package_name "$(basename "$archive")")
            if [ ! -d "$LOCAL_PACKAGES/$pkg_name" ]; then
                if $interactive_mode; then
                    print_warning "Orphaned archive: $(basename "$archive")"
                    read -p "Remove orphaned archive '$(basename "$archive")'? [y/N]: " remove_choice
                    if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
                        rm -f "$archive"
                        print_info "Archive removed."
                    fi
                else
                    print_warning "Orphaned archive found: $(basename "$archive"). Run 'ubrew verify --interactive' to clean up."
                fi
            fi
        done
    fi

    print_success "PATH verification complete."
}
