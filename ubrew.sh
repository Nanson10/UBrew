#!/bin/bash

###############################################################################
# ubrew.sh - Simple Package Manager for Ubuntu
# 
# A homebrew-like package manager for Ubuntu that downloads, extracts,
# compiles (if needed), and manages packages locally.
#
# Usage: ubrew.sh [add|remove|list|init|uninit] [options]
###############################################################################

# Only set strict mode when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

# Configuration
UBREW_HOME="${HOME}/.ubrew"
LOCAL_PACKAGES="${HOME}/local_packages"
ARCHIVES_DIR="${LOCAL_PACKAGES}/archives"
UBREW_PATH_FILE="${UBREW_HOME}/path.conf"
UBREW_LOG="${UBREW_HOME}/ubrew.log"
UBREW_TEMP="${UBREW_HOME}/temp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Initialization Functions
###############################################################################

initialize() {
    # Create necessary directories
    mkdir -p "$UBREW_HOME"
    mkdir -p "$LOCAL_PACKAGES"
    mkdir -p "$ARCHIVES_DIR"
    mkdir -p "$UBREW_TEMP"
    
    # Clean up old temp files (older than 1 day)
    find "$UBREW_TEMP" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Initialize path config with proper structure
    if [[ ! -f "$UBREW_PATH_FILE" ]]; then
        cat > "$UBREW_PATH_FILE" <<'EOF'
#!/bin/bash
# ubrew PATH configuration file
# 
# WARNING: DO NOT MANUALLY EDIT THE SECTION BETWEEN THE MARKERS BELOW!
# This section is automatically managed by ubrew.sh
# Manual edits will be overwritten when packages are added or removed.
#
# === BEGIN UBREW MANAGED PATHS ===
# (ubrew will automatically add package paths here)
# === END UBREW MANAGED PATHS ===
#
# You may add your own custom PATH modifications below this line:

EOF
    fi
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$UBREW_LOG"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $@"
}

print_success() {
    echo -e "${GREEN}✓${NC} $@"
}

print_error() {
    echo -e "${RED}✗${NC} $@"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $@"
}

###############################################################################
# Utility Functions
###############################################################################

# Extract filename from URL
get_filename_from_url() {
    local url=$1
    basename "$url" | sed 's/?.*$//'
}

# Infer package name from archive name or directory
infer_package_name() {
    local input=$1
    ###############################################################################
    # Source modular scripts
    ###############################################################################

    source "$(dirname "$0")/scripts/initialize.sh"
    source "$(dirname "$0")/scripts/log.sh"
    source "$(dirname "$0")/scripts/print.sh"
    source "$(dirname "$0")/scripts/utils.sh"
    source "$(dirname "$0")/scripts/download_and_extract.sh"
    source "$(dirname "$0")/scripts/compile.sh"
    source "$(dirname "$0")/scripts/path.sh"
    source "$(dirname "$0")/scripts/cmd_help.sh"
    source "$(dirname "$0")/scripts/cmd_list.sh"
    source "$(dirname "$0")/scripts/cmd_remove.sh"
    source "$(dirname "$0")/scripts/cmd_add.sh"
    source "$(dirname "$0")/scripts/cmd_verify.sh"
    source "$(dirname "$0")/scripts/cmd_init.sh"
    source "$(dirname "$0")/scripts/cmd_uninit.sh"
            fi
        done
        
        if [[ $found -eq 0 ]]; then
            print_warning "PATH contains '$configured' but package is not installed"
            ((issues_found++))
            
            # Fix: Remove from PATH
            sed -i.bak "/# ubrew: $configured\$/d" "$UBREW_PATH_FILE"
            rm -f "$UBREW_PATH_FILE.bak"
            
            print_success "Fixed: Removed '$configured' from PATH"
            ((issues_fixed++))
        fi
    done
    
    # Verify that package directories actually exist and are accessible
    for package in "${installed_packages[@]}"; do
        local package_dir="$LOCAL_PACKAGES/$package"
        local bin_dir="$package_dir/bin"
        
        if [[ ! -d "$bin_dir" ]]; then
            print_warning "Package '$package' missing bin directory"
            ((issues_found++))
            mkdir -p "$bin_dir"
            print_success "Fixed: Created bin directory for '$package'"
            ((issues_fixed++))
        fi
    done
    
    # Summary
    if [[ $issues_found -eq 0 ]]; then
        print_success "PATH configuration is correct! All packages are properly configured."
    else
        print_info "Found $issues_found issue(s), fixed $issues_fixed"
        cmd_verify() {
            print_info "Verifying ubrew archives and packages..."
            ensure_path_file_structure
            local issues_found=0
            local issues_fixed=0

            # Get all archive files
            local archive_files=()
            if [[ -d "$ARCHIVES_DIR" ]]; then
                while IFS= read -r -d '' archive; do
                    archive_files+=("$archive")
                done < <(find "$ARCHIVES_DIR" -type f -print0)
            fi

            # Get all installed packages
            local installed_packages=()
            if [[ -d "$LOCAL_PACKAGES" ]]; then
                while IFS= read -r -d '' package_dir; do
                    local package_name=$(basename "$package_dir")
                    if [[ -f "$package_dir/.ubrew_metadata" ]]; then
                        installed_packages+=("$package_name")
                    fi
                done < <(find "$LOCAL_PACKAGES" -maxdepth 1 -type d -not -path "$LOCAL_PACKAGES" -not -path "$ARCHIVES_DIR" -print0)
            fi

            # Compile orphaned archives (archives with no corresponding package)
            for archive_path in "${archive_files[@]}"; do
                local archive_name=$(basename "$archive_path")
                local package_name=$(infer_package_name "$archive_name")
                local package_dir="$LOCAL_PACKAGES/$package_name"
                if [[ ! -d "$package_dir" ]] || [[ ! -f "$package_dir/.ubrew_metadata" ]]; then
                    print_warning "Archive '$archive_name' has no package. Attempting to compile..."
                    mkdir -p "$package_dir"
                    # Extract and compile
                    if download_and_extract "$archive_path" "$package_dir"; then
                        local language=$(detect_language "$package_dir")
                        print_info "Detected language: $language"
                        if check_build_tools "$language"; then
                            if compile_package "$package_dir" "$language"; then
                                                                cat > "$package_dir/.ubrew_metadata" <<EOF
{
    "name": "$package_name",
    "url": "archive:$archive_name",
    "language": "$language",
    "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "installed_by": "ubrew.sh"
}
EOF
                                print_success "Compiled and installed package '$package_name' from archive."
                                ((issues_fixed++))
                            else
                                print_error "Failed to compile package from archive '$archive_name'."
                                # Prompt to remove archive
                                read -p "Remove archive '$archive_name'? (y/n) " -n 1 -r
                                echo
                                if [[ $REPLY =~ ^[Yy]$ ]]; then
                                    rm -f "$archive_path"
                                    print_success "Removed archive '$archive_name'."
                                    ((issues_fixed++))
                                else
                                    print_warning "Archive '$archive_name' kept."
                                fi
                                rm -rf "$package_dir"
                                ((issues_found++))
                            fi
                        else
                            print_error "Missing build tools for '$language'. Skipping compilation."
                            ((issues_found++))
                        fi
                    else
                        print_error "Failed to extract archive '$archive_name'."
                        read -p "Remove archive '$archive_name'? (y/n) " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            rm -f "$archive_path"
                            print_success "Removed archive '$archive_name'."
                            ((issues_fixed++))
                        else
                            print_warning "Archive '$archive_name' kept."
                        fi
                        rm -rf "$package_dir"
                        ((issues_found++))
                    fi
                fi
            done

            # Remove orphaned packages (packages with no corresponding archive)
            for package in "${installed_packages[@]}"; do
                local found=0
                for archive_path in "${archive_files[@]}"; do
                    local archive_name=$(basename "$archive_path")
                    local archive_pkg=$(infer_package_name "$archive_name")
                    if [[ "$package" == "$archive_pkg" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    print_warning "Package '$package' is orphaned (no archive). Removing..."
                    rm -rf "$LOCAL_PACKAGES/$package"
                    print_success "Removed orphaned package '$package'."
                    ((issues_fixed++))
                fi
            done

            # Ensure PATH configuration is correct (last step)
            print_info "Ensuring PATH configuration..."
            # Get list of packages in PATH config
            local configured_packages=()
            if [[ -f "$UBREW_PATH_FILE" ]]; then
                while IFS= read -r line; do
                    if [[ "$line" =~ \#\ ubrew:\ (.+)$ ]]; then
                        configured_packages+=("${BASH_REMATCH[1]}")
                    fi
                done < "$UBREW_PATH_FILE"
            fi
            # Add missing packages to PATH
            for package in "${installed_packages[@]}"; do
                local found=0
                for configured in "${configured_packages[@]}"; do
                    if [[ "$package" == "$configured" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    print_warning "Package '$package' is installed but not in PATH"
                    local package_dir="$LOCAL_PACKAGES/$package"
                    local bin_dir="$package_dir/bin"
                    mkdir -p "$bin_dir"
                    sed -i.bak "/^# === END UBREW MANAGED PATHS ===/i\\
                    rm -f "$UBREW_PATH_FILE.bak"
                    print_success "Fixed: Added '$package' to PATH"
                    ((issues_fixed++))
                fi
            done
            # Remove PATH entries without corresponding packages
            for configured in "${configured_packages[@]}"; do
                local found=0
                for package in "${installed_packages[@]}"; do
                    if [[ "$configured" == "$package" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    print_warning "PATH contains '$configured' but package is not installed"
                    sed -i.bak "/# ubrew: $configured\$/d" "$UBREW_PATH_FILE"
                    rm -f "$UBREW_PATH_FILE.bak"
                    print_success "Fixed: Removed '$configured' from PATH"
                    ((issues_fixed++))
                fi
            done
            # Ensure bin directories exist
            for package in "${installed_packages[@]}"; do
                local package_dir="$LOCAL_PACKAGES/$package"
                local bin_dir="$package_dir/bin"
                if [[ ! -d "$bin_dir" ]]; then
                    print_warning "Package '$package' missing bin directory"
                    mkdir -p "$bin_dir"
                    print_success "Fixed: Created bin directory for '$package'"
                    ((issues_fixed++))
                fi
            done

            # Summary
            if [[ $issues_found -eq 0 ]]; then
                print_success "Verification complete! All archives and packages are properly linked."
            else
                print_info "Found $issues_found issue(s), fixed $issues_fixed"
                print_success "Verification complete!"
            fi
            log "INFO" "Verification completed: $issues_found issues found, $issues_fixed fixed"
            return 0
        }
    local package_name=$1
    local package_dir="$LOCAL_PACKAGES/$package_name"
    
    if [[ ! -d "$package_dir" ]]; then
        print_error "Package '$package_name' not found"
        return 1
    fi
    
    print_warning "Removing package: ${BLUE}${package_name}${NC}"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removal cancelled"
        return 0
    fi
    
    # Remove from PATH config
    remove_package_path "$package_name"
    
    # Remove package directory
    rm -rf "$package_dir"
    print_success "Package '${package_name}' removed successfully!"
    log "INFO" "Package removed: $package_name"
    
    return 0
}

cmd_list() {
    print_info "Installed packages:"
    
    if [[ ! -d "$LOCAL_PACKAGES" ]] || [[ -z "$(ls -A "$LOCAL_PACKAGES")" ]]; then
        print_warning "No packages installed"
        return 0
    fi
    
    local count=0
    while IFS= read -r -d '' package_dir; do
        if [[ -f "$package_dir/.ubrew_metadata" ]]; then
            local metadata=$(cat "$package_dir/.ubrew_metadata")
            local name=$(echo "$metadata" | grep -o '"name":"[^"]*' | cut -d'"' -f4)
            local language=$(echo "$metadata" | grep -o '"language":"[^"]*' | cut -d'"' -f4)
            local installed_at=$(echo "$metadata" | grep -o '"installed_at":"[^"]*' | cut -d'"' -f4)
            
            printf "  ${GREEN}✓${NC} %-20s [%s] %s\n" "$name" "$language" "$installed_at"
            ((count++))
        fi
    done < <(find "$LOCAL_PACKAGES" -maxdepth 1 -type d -not -path "$LOCAL_PACKAGES" -print0)
    
    if [[ $count -eq 0 ]]; then
        print_warning "No packages with valid metadata found"
    else
        print_info "Total: $count package(s) installed"
    fi
    
    return 0
}

cmd_init() {
    print_info "Initializing ubrew..."
    
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")}" && pwd)/ubrew.sh"
    local source_line="source \"$script_path\"  # ubrew.sh initialization"
    
    # Initialize ubrew home
    initialize
    
    local updated=0
    
    # Update ~/.bashrc if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "ubrew.sh initialization" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# ubrew.sh configuration" >> "$HOME/.bashrc"
            echo "$source_line" >> "$HOME/.bashrc"
            echo "if [[ -f \"$UBREW_PATH_FILE\" ]]; then source \"$UBREW_PATH_FILE\"; fi" >> "$HOME/.bashrc"
            print_success "Added ubrew to ~/.bashrc"
            ((updated++))
        else
            print_warning "ubrew already in ~/.bashrc"
        fi
    fi
    
    # Update ~/.zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "ubrew.sh initialization" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# ubrew.sh configuration" >> "$HOME/.zshrc"
            echo "$source_line" >> "$HOME/.zshrc"
            echo "if [[ -f \"$UBREW_PATH_FILE\" ]]; then source \"$UBREW_PATH_FILE\"; fi" >> "$HOME/.zshrc"
            print_success "Added ubrew to ~/.zshrc"
            ((updated++))
        else
            print_warning "ubrew already in ~/.zshrc"
        fi
    fi
    
    if [[ $updated -eq 0 ]]; then
        print_warning "ubrew already initialized"
        return 0
    fi
    
    print_success "ubrew initialized successfully!"
    print_info "Please reload your shell:"
    echo "    exec \$SHELL"
    
    log "INFO" "ubrew initialized by user"
    return 0
}

cmd_uninit() {
    print_warning "Removing ubrew from shell configuration files..."
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninitialization cancelled"
        return 0
    fi
    
    local updated=0
    
    # Remove from ~/.bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "ubrew.sh initialization" "$HOME/.bashrc" 2>/dev/null; then
            sed -i.bak '/# ubrew.sh configuration/,/ubrew.sh initialization/d' "$HOME/.bashrc"
            sed -i.bak '/if \[\[ -f.*UBREW_PATH_FILE/d' "$HOME/.bashrc"
            rm -f "$HOME/.bashrc.bak"
            print_success "Removed ubrew from ~/.bashrc"
            ((updated++))
        fi
    fi
    
    # Remove from ~/.zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "ubrew.sh initialization" "$HOME/.zshrc" 2>/dev/null; then
            sed -i.bak '/# ubrew.sh configuration/,/ubrew.sh initialization/d' "$HOME/.zshrc"
            sed -i.bak '/if \[\[ -f.*UBREW_PATH_FILE/d' "$HOME/.zshrc"
            rm -f "$HOME/.zshrc.bak"
            print_success "Removed ubrew from ~/.zshrc"
            ((updated++))
        fi
    fi
    
    if [[ $updated -eq 0 ]]; then
        print_warning "ubrew not found in shell configuration"
        return 1
    fi
    
    print_success "ubrew uninitialized successfully!"
    print_info "Please reload your shell:"
    echo "    exec \$SHELL"
    
    log "INFO" "ubrew uninitialized by user"
    return 0
}

cmd_help() {
cat <<EOF
${BLUE}ubrew.sh${NC} - Simple Package Manager for Ubuntu

${BLUE}Usage:${NC}
  ubrew.sh [command] [options]

${BLUE}Commands:${NC}
  init                   Initialize ubrew (adds to ~/.bashrc and ~/.zshrc)
  uninit                 Uninstall ubrew (removes from shell config)
  
  add <url>              Download, extract, and install a package from a URL
                         Supports: tar.gz, tar.bz2, tar.xz, zip, 7z
                         
  remove <package-name>  Remove an installed package
                         
  list                   Show all installed packages
  
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

###############################################################################
# Main Entry Point
###############################################################################

main() {
    initialize
    
    if [[ $# -eq 0 ]]; then
        cmd_help
        return 1
    fi
    
    local command=$1
    shift
    
    case $command in
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
        *)
            print_error "Unknown command: $command"
            cmd_help
            return 1
            ;;
    esac
}

# Only execute main when script is run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
