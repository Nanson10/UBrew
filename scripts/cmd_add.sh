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
    local archive_path="$LOCAL_PACKAGES/archives/$filename"
    download_and_extract "$url" "$archive_path" "$package_name"
    if [ $? -ne 0 ]; then
        print_error "Download or extraction failed."
        return 1
    fi
    compile_package "$package_name" "$archive_path"
    if [ $? -ne 0 ]; then
        print_warning "Compilation failed."
        read -p "Remove archive for '$package_name'? [y/N]: " remove_choice
        if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
            rm -f "$archive_path"
            print_info "Archive removed."
        fi
        return 1
    fi
    update_package_path "$package_name"
    log "Added package: $package_name from $url"
    print_success "Package '$package_name' installed."
}
