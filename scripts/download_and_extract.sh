#!/bin/bash

download_and_extract() {
    local url=$1
    local dest=$2
    local archive_name=$(get_filename_from_url "$url")
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
    mkdir -p "$dest"
    if [[ "$archive_path" == *.tar.gz ]] || [[ "$archive_path" == *.tgz ]]; then
        tar -xzf "$archive_path" -C "$dest" --strip-components=1 2>/dev/null || tar -xzf "$archive_path" -C "$dest"
    elif [[ "$archive_path" == *.tar.bz2 ]]; then
        tar -xjf "$archive_path" -C "$dest" --strip-components=1 2>/dev/null || tar -xjf "$archive_path" -C "$dest"
    elif [[ "$archive_path" == *.tar.xz ]]; then
        tar -xJf "$archive_path" -C "$dest" --strip-components=1 2>/dev/null || tar -xJf "$archive_path" -C "$dest"
    elif [[ "$archive_path" == *.zip ]]; then
        unzip -q "$archive_path" -d "$dest"
        local contents=$(ls -A "$dest")
        if [[ $(echo "$contents" | wc -l) -eq 1 ]] && [[ -d "$dest/$contents" ]]; then
            mv "$dest/$contents"/* "$dest/" 2>/dev/null || true
            rmdir "$dest/$contents" 2>/dev/null || true
        fi
    elif [[ "$archive_path" == *.7z ]]; then
        7z x "$archive_path" -o"$dest" >/dev/null 2>&1 || {
            print_error "7z extraction failed. Is 7zip installed?"
            rm -f "$archive_path"
            return 1
        }
    else
        if file "$archive_path" | grep -q "gzip"; then
            tar -xzf "$archive_path" -C "$dest" --strip-components=1 2>/dev/null || tar -xzf "$archive_path" -C "$dest"
        elif file "$archive_path" | grep -q "Zip"; then
            unzip -q "$archive_path" -d "$dest"
        else
            print_error "Unknown archive format"
            rm -f "$archive_path"
            return 1
        fi
    fi
    print_success "Extracted successfully"
    return 0
}
