#!/bin/bash

cmd_init() {
    if [[ "$1" == "-f" || "$1" == "--force" ]]; then
        read -p "Are you sure you want to clear all ubrew data and re-initialize? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Clearing existing ubrew installation..."
            rm -rf "$UBREW_ROOT"
            rm -rf "$UBREW_HOME"
            print_success "Cleared."
            initialize
            print_success "ubrew re-initialized."
        else
            print_info "Initialization cancelled."
        fi
    else
        if [ -d "$UBREW_HOME" ] || [ -d "$UBREW_ROOT" ]; then
            print_warning "ubrew seems to be already initialized."
            print_info "If you want to start fresh, use 'ubrew init --force'"
            exit 1
        fi
        initialize
        print_success "ubrew initialized."
        
        # Add to shell config
        for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [ -f "$rc_file" ]; then
                if ! grep -q "UBREW" "$rc_file"; then
                    echo -e "\n# === BEGIN UBREW INIT ===" >> "$rc_file"
                    echo "source \"$UBREW_PATH_FILE\"" >> "$rc_file"
                    echo "# === END UBREW INIT ===" >> "$rc_file"
                    print_info "Added ubrew to $rc_file"
                fi
            fi
        done
        
        print_warning "Please reload your shell for changes to take effect: exec \$SHELL"
    fi
}
