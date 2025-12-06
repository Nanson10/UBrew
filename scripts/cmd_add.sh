#!/bin/bash

cmd_add() {
    local url="$1"
    if [ -z "$url" ]; then
        print_error "No URL provided."
        return 1
    fi
    local filename
    filename=$(get_filename_from_url "$url")
    local package_name
    package_name=$(infer_package_name "$filename")
    local package_dir="$LOCAL_PACKAGES/$package_name"
    
    # Download and extract
    download_and_extract "$url" "$package_dir"
    if [ $? -ne 0 ]; then
        print_error "Download or extraction failed."
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
