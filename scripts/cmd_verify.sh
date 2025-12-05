#!/bin/bash

cmd_verify() {
    print_info "Verifying PATH configuration..."
    ensure_path_file_structure
    local valid_packages=()
    local orphaned_paths=()
    if [ -f "$UBREW_PATH_FILE" ]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            local pkg_name
            pkg_name=$(basename "$line")
            if [ -d "$LOCAL_PACKAGES/$pkg_name" ]; then
                valid_packages+=("$pkg_name")
            else
                orphaned_paths+=("$pkg_name")
            fi
        done < "$UBREW_PATH_FILE"
    fi
    for orphan in "${orphaned_paths[@]}"; do
        print_warning "Orphaned PATH entry: $orphan"
        remove_package_path "$orphan"
    done
    # Check for orphaned archives
    if [ -d "$LOCAL_PACKAGES/archives" ]; then
        for archive in "$LOCAL_PACKAGES/archives"/*; do
            [ -f "$archive" ] || continue
            local pkg_name
            pkg_name=$(infer_package_name "$(basename "$archive")")
            if [ ! -d "$LOCAL_PACKAGES/$pkg_name" ]; then
                print_warning "Orphaned archive: $(basename "$archive")"
                read -p "Remove orphaned archive '$(basename "$archive")'? [y/N]: " remove_choice
                if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
                    rm -f "$archive"
                    print_info "Archive removed."
                fi
            fi
        done
    fi
    print_success "PATH verification complete."
}
