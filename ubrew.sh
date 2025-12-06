#!/bin/bash

#######################################
# ubrew.sh - Ubuntu Package Manager
# A simple, homebrew-like package manager for Ubuntu
#######################################

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Configuration
export UBREW_HOME="${HOME}/.ubrew"
export UBREW_ROOT="${HOME}/local_packages"
export LOCAL_PACKAGES="${UBREW_ROOT}/packages"
export ARCHIVES_DIR="${UBREW_ROOT}/archives"
export UBREW_TEMP="${UBREW_HOME}/temp"
export UBREW_PATH_FILE="${UBREW_HOME}/path.conf"
export UBREW_LOG="${UBREW_HOME}/ubrew.log"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# Source utility functions
source "${SCRIPTS_DIR}/print.sh"
source "${SCRIPTS_DIR}/log.sh"
source "${SCRIPTS_DIR}/utils.sh"
source "${SCRIPTS_DIR}/path.sh"
source "${SCRIPTS_DIR}/initialize.sh"
source "${SCRIPTS_DIR}/download_and_extract.sh"
source "${SCRIPTS_DIR}/compile.sh"

# Source command functions
source "${SCRIPTS_DIR}/cmd_init.sh"
source "${SCRIPTS_DIR}/cmd_uninit.sh"
source "${SCRIPTS_DIR}/cmd_add.sh"
source "${SCRIPTS_DIR}/cmd_remove.sh"
source "${SCRIPTS_DIR}/cmd_list.sh"
source "${SCRIPTS_DIR}/cmd_verify.sh"
source "${SCRIPTS_DIR}/cmd_help.sh"

#######################################
# Main command dispatcher
#######################################
main() {
    local command="$1"
    shift

    case "$command" in
        init)
            cmd_init "$@"
            ;;
        uninit)
            cmd_uninit "$@"
            ;;
        add)
            cmd_add "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        verify)
            cmd_verify "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        "")
            print_error "No command provided."
            echo ""
            cmd_help
            exit 1
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
