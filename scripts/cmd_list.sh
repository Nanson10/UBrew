#!/bin/bash

cmd_list() {
    local show_path=false
    if [[ "$1" == "-p" ]]; then
        show_path=true
    fi

    echo "${BLUE}Installed packages:${NC}"
    if [ -d "$LOCAL_PACKAGES" ]; then
        for pkg in "$LOCAL_PACKAGES"/*; do
            [ -d "$pkg" ] || continue
            if [ "$show_path" = true ]; then
                echo "- $pkg"
            else
                local pkg_name
                pkg_name=$(basename "$pkg")
                echo "- $pkg_name"
            fi
        done
    else
        echo "No packages installed."
    fi
}
