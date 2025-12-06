#!/bin/bash

cmd_help() {
cat <<EOF
${BLUE}ubrew.sh${NC} - Simple Package Manager for Ubuntu

${BLUE}Usage:${NC}
  ubrew.sh [command] [options]

${BLUE}Commands:${NC}
  init                   Initialize ubrew (automatically adds to shell config)
  uninit                 Uninstall ubrew (automatically removes from shell config)
  
  add <url_or_filepath>  Download, extract, and install a package from a URL or local file.
                         Supports: tar.gz, tar.bz2, tar.xz, zip, 7z
                         
  remove <package-name>  Remove an installed package
                         
  list [-p]              Show all installed packages. Use -p to show full paths.
  
  verify                 Verify and fix PATH configuration
                         Ensures all installed packages are in PATH and
                         removes orphaned entries
                         
  help                   Show this help message

${BLUE}Examples:${NC}
  ubrew.sh init
  ubrew.sh add https://github.com/user/project/archive/refs/tags/v1.0.tar.gz
  ubrew.sh remove project
  ubrew.sh list
  ubrew.sh verify
  ubrew.sh uninit

${BLUE}Configuration:${NC}
  UBrew root directory:     $UBREW_ROOT
  Local packages directory: $LOCAL_PACKAGES
  Configuration file: $UBREW_PATH_FILE
  Log file: $UBREW_LOG

${BLUE}Supported Languages:${NC}
  - C (with Make)
  - C++ (with Make or CMake)
  - C# (.NET)
  - Java (Maven or Gradle)
  - Python, Node.js, Go, Rust (no compilation needed)

${BLUE}Features:${NC}
  ✓ Automatic language detection
  ✓ Automatic compilation when needed
  ✓ Automatic PATH management
  ✓ PATH verification and repair
  ✓ Installation logging
  ✓ Metadata tracking
EOF
}
