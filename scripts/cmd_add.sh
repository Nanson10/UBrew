#!/bin/bash

cmd_add() {
    local source_arg="$1"
    if [ -z "$source_arg" ]; then
        print_error "No URL or file path provided."
        return 1
    fi

    local archive_path
    if [[ -f "$source_arg" ]]; then
        print_info "Using local file: $source_arg"
        local filename
        filename=$(basename "$source_arg")
        archive_path="$ARCHIVES_DIR/$filename"
        if ! cp "$source_arg" "$archive_path"; then
            print_error "Failed to copy '$source_arg' to '$ARCHIVES_DIR'."
            return 1
        fi
        print_success "Copied to archives."
    else
        print_info "Assuming URL: $source_arg"
        archive_path=$(download "$source_arg")
        if [ $? -ne 0 ]; then
            print_error "Download failed."
            return 1
        fi
    fi

    local filename
    filename=$(basename "$archive_path")
    local package_name
    package_name=$(infer_package_name "$filename")
    local package_dir="$LOCAL_PACKAGES/$package_name"

    extract "$archive_path" "$package_dir"
    if [ $? -ne 0 ]; then
        print_error "Extraction failed."
        return 1
    fi
    
    # Detect language and compile if needed
    local language
    language=$(detect_language "$package_dir")
    
    compile_package "$package_dir" "$language"
    if [ $? -ne 0 ]; then
        print_warning "Compilation failed or not needed."
        read -p "Remove package for '$package_name'? [y/N]: " remove_choice
        if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
            rm -rf "$package_dir"
            rm -f "$ARCHIVES_DIR/${filename}"
            print_info "Package removed."
        fi
        return 1
    fi
    
    update_package_path "$package_name"
    log "INFO" "Added package: $package_name from $url"
    print_success "Package '$package_name' installed."
}
