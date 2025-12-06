#!/bin/bash

cmd_uninit() {
    # Remove ubrew from shell config
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # Use sed to remove the block
            sed -i.bak '/# === BEGIN UBREW INIT ===/,/# === END UBREW INIT ===/d' "$rc_file"
            # Check if the file is empty or only contains whitespace
            if ! grep -q '[^[:space:]]' "$rc_file"; then
                rm "$rc_file" # Remove empty file
            fi
            rm -f "${rc_file}.bak"
        fi
    done
    print_success "ubrew uninstalled from shell config."
    print_warning "Please reload your shell for changes to take effect: exec \$SHELL"
}
