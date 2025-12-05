#!/bin/bash

cmd_list() {
    echo "${BLUE}Installed packages:${NC}"
    if [ -d "$LOCAL_PACKAGES" ]; then
        for pkg in "$LOCAL_PACKAGES"/*; do
            [ -d "$pkg" ] || continue
            pkg_name=$(basename "$pkg")
            echo "- $pkg_name"
        done
    else
        echo "No packages installed."
    fi
}
