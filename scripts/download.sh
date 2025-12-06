#!/bin/bash

download() {
    local url=$1
    local archive_name
    archive_name=$(get_filename_from_url "$url")
    local archive_path="$ARCHIVES_DIR/$archive_name"
    print_info "Downloading from: $url"
    if [[ ! -f "$archive_path" ]]; then
        if ! wget -q "$url" -O "$archive_path" 2>/dev/null; then
            print_error "Failed to download package from $url"
            rm -f "$archive_path"
            return 1
        fi
        print_success "Downloaded successfully"
    else
        print_info "Archive already exists: $archive_path"
    fi
    echo "$archive_path"
    return 0
}
