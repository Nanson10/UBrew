#!/bin/bash

cmd_remove() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        print_error "No package name provided."
        return 1
    fi
    local package_dir="$LOCAL_PACKAGES/$package_name"
    if [ ! -d "$package_dir" ]; then
        print_error "Package '$package_name' not found."
        return 1
    fi
    rm -rf "$package_dir"
    rm -f "$ARCHIVES_DIR/${package_name}."*
    remove_package_path "$package_name"
    log "INFO" "Removed package: $package_name"
    print_success "Package '$package_name' removed."
}
