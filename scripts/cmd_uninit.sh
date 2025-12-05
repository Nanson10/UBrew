#!/bin/bash

cmd_uninit() {
    # Remove ubrew from shell config
    sed -i '' '/ubrew.sh/d' ~/.bashrc 2>/dev/null
    sed -i '' '/ubrew.sh/d' ~/.zshrc 2>/dev/null
    print_success "ubrew uninstalled from shell config."
}
