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
    # Remove common archive extensions
    local name=$(basename "$input" | sed -E 's/\.(tar\.(gz|bz2|xz)|zip|tgz|7z)$//')
    # Remove version numbers and common separators
    name=$(echo "$name" | sed -E 's/-v?[0-9]+(\.[0-9]+)*.*$//')
    echo "$name"
}

# Detect programming language of a project
detect_language() {
    local dir=$1
    
    if [[ -f "$dir/pom.xml" ]]; then
        echo "java"
    elif [[ -f "$dir/build.gradle" ]] || [[ -f "$dir/build.gradle.kts" ]]; then
        echo "java"
    elif [[ -f "$dir/go.mod" ]]; then
        echo "go"
    elif [[ -f "$dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$dir/setup.py" ]] || [[ -f "$dir/pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "$dir/package.json" ]]; then
        echo "node"
    elif [[ -f "$dir/CMakeLists.txt" ]]; then
        # Check for language hints
        if grep -q "project.*LANGUAGES.*CXX" "$dir/CMakeLists.txt" 2>/dev/null; then
            echo "cpp"
        elif grep -q "project.*LANGUAGES.*C" "$dir/CMakeLists.txt" 2>/dev/null; then
            echo "c"
        else
            echo "cmake"
        fi
    elif [[ -f "$dir/Makefile" ]] || [[ -f "$dir/makefile" ]]; then
        echo "make"
    elif find "$dir" -maxdepth 2 -name "*.csproj" | grep -q .; then
        echo "csharp"
    elif find "$dir" -maxdepth 2 -name "*.java" | grep -q .; then
        echo "java"
    elif find "$dir" -maxdepth 2 -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" | grep -q .; then
        echo "cpp"
    elif find "$dir" -maxdepth 2 -name "*.c" | grep -q .; then
        echo "c"
    else
        echo "unknown"
    fi
}

# Check if required build tools are installed
check_build_tools() {
    local language=$1
    local missing=()
    
    case $language in
        c|cpp|make)
            command -v gcc >/dev/null 2>&1 || missing+=("gcc")
            command -v g++ >/dev/null 2>&1 || missing+=("g++")
            command -v make >/dev/null 2>&1 || missing+=("make")
            ;;
        csharp)
            command -v dotnet >/dev/null 2>&1 || missing+=("dotnet")
            ;;
        java)
            command -v javac >/dev/null 2>&1 || missing+=("javac")
            ;;
        cmake)
            command -v cmake >/dev/null 2>&1 || missing+=("cmake")
            command -v gcc >/dev/null 2>&1 || missing+=("gcc")
            command -v make >/dev/null 2>&1 || missing+=("make")
            ;;
    esac
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

###############################################################################
# Package Management Functions
###############################################################################

# Download and extract package
download_and_extract() {
    local url=$1
    local dest=$2
    local archive_name=$(get_filename_from_url "$url")
    local archive_path="$ARCHIVES_DIR/$archive_name"

    print_info "Downloading from: $url"

    # Download archive if not already present
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

    # Create destination and extract
    mkdir -p "$dest"

    # Detect archive type and extract
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

# Compile package based on detected language
compile_package() {
    local package_dir=$1
    local language=$2
    
    print_info "Detected language: ${BLUE}${language}${NC}"
    
    case $language in
        make|c|cpp)
            compile_make "$package_dir"
            ;;
        cmake)
            compile_cmake "$package_dir"
            ;;
        csharp)
            compile_csharp "$package_dir"
            ;;
        java)
            compile_java "$package_dir"
            ;;
        *)
            print_warning "No compilation needed for $language"
            return 0
            ;;
    esac
}

compile_make() {
    local dir=$1
    
    if [[ ! -f "$dir/Makefile" ]] && [[ ! -f "$dir/makefile" ]]; then
        print_warning "Makefile not found"
        return 1
    fi
    
    print_info "Running make..."
    cd "$dir"
    
    if ! make 2>&1 | tee -a "$UBREW_LOG"; then
        print_error "Make compilation failed"
        return 1
    fi
    
    print_success "Compilation completed"
    return 0
}

compile_cmake() {
    local dir=$1
    
    if [[ ! -f "$dir/CMakeLists.txt" ]]; then
        print_warning "CMakeLists.txt not found"
        return 1
    fi
    
    print_info "Running cmake..."
    cd "$dir"
    
    mkdir -p build
    cd build
    
    if ! cmake .. 2>&1 | tee -a "$UBREW_LOG"; then
        print_error "CMake configuration failed"
        return 1
    fi
    
    if ! make 2>&1 | tee -a "$UBREW_LOG"; then
        print_error "CMake make failed"
        return 1
    fi
    
    print_success "Compilation completed"
    return 0
}

compile_csharp() {
    local dir=$1
    
    print_info "Running dotnet build..."
    cd "$dir"
    
    if ! dotnet build -c Release 2>&1 | tee -a "$UBREW_LOG"; then
        print_error "C# compilation failed"
        return 1
    fi
    
    print_success "Compilation completed"
    return 0
}

compile_java() {
    local dir=$1
    
    print_info "Running Java compilation..."
    cd "$dir"
    
    if [[ -f "pom.xml" ]]; then
        if ! mvn clean package -DskipTests 2>&1 | tee -a "$UBREW_LOG"; then
            print_error "Maven build failed"
            return 1
        fi
    elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        if ! gradle build -x test 2>&1 | tee -a "$UBREW_LOG"; then
            print_error "Gradle build failed"
            return 1
        fi
    else
        print_warning "No Maven or Gradle configuration found"
        return 1
    fi
    
    print_success "Compilation completed"
    return 0
}

# Find executable in compiled package
find_executable() {
    local package_dir=$1
    local language=$2
    
    case $language in
        make|c|cpp)
            # Look for executables in common locations
            find "$package_dir" -maxdepth 2 -type f -executable | head -1
            ;;
        cmake)
            # Look in build directory
            find "$package_dir/build" -maxdepth 1 -type f -executable | head -1
            ;;
        csharp)
            # Look for .dll or .exe files in bin/Release
            find "$package_dir" -path "*/bin/Release/*" -name "*.dll" -o -name "*.exe" | head -1
            ;;
        java)
            # Look for jar files
            find "$package_dir" -name "*.jar" | head -1
            ;;
        *)
            return 1
            ;;
    esac
}

# Update PATH with package executables
update_package_path() {
    local package_name=$1
    local package_dir=$2
    
    # Simply call verify to ensure everything is in sync
    # The verify function will handle adding missing packages
    cmd_verify >/dev/null 2>&1
    
    # Double-check that the package was added
    if grep -q "# ubrew: $package_name\$" "$UBREW_PATH_FILE"; then
        print_success "Added $package_name to PATH"
        
        # Source the updated path file in current shell if possible
        if [[ -n "$BASH_VERSION" ]] || [[ -n "$ZSH_VERSION" ]]; then
            source "$UBREW_PATH_FILE" 2>/dev/null || true
        fi
    fi
}

# Remove package from PATH configuration
remove_package_path() {
    local package_name=$1
    
    # Simply call verify to ensure everything is in sync
    # The verify function will handle removing orphaned entries
    cmd_verify >/dev/null 2>&1
    
    # Confirm removal
    if ! grep -q "# ubrew: $package_name\$" "$UBREW_PATH_FILE" 2>/dev/null; then
        print_success "Removed $package_name from PATH"
    fi
}

# Ensure path file has the proper structure with warnings
ensure_path_file_structure() {
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
    else
        # Check if markers exist, if not add them
        if ! grep -q "^# === BEGIN UBREW MANAGED PATHS ===" "$UBREW_PATH_FILE"; then
            # Backup existing entries in ubrew directory
            local temp_file="${UBREW_HOME}/temp_path_backup_$$_$(date +%s)"
            if grep -q "# ubrew:" "$UBREW_PATH_FILE"; then
                grep "# ubrew:" "$UBREW_PATH_FILE" > "$temp_file"
            fi
            
            # Recreate file with structure
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
EOF
            
            # Add back existing entries
            if [[ -s "$temp_file" ]]; then
                cat "$temp_file" >> "$UBREW_PATH_FILE"
            fi
            
            cat >> "$UBREW_PATH_FILE" <<'EOF'
# === END UBREW MANAGED PATHS ===
#
# You may add your own custom PATH modifications below this line:

EOF
            rm -f "$temp_file"
        fi
    fi
}

# Verify and synchronize PATH configuration with installed packages
# This function ensures that:
# 1. All installed packages have their paths in the config
# 2. All paths in the config correspond to actual installed packages
# 3. The path file has the proper structure
cmd_verify() {
    print_info "Verifying ubrew PATH configuration..."
    
    # Ensure proper structure
    ensure_path_file_structure
    
    local issues_found=0
    local issues_fixed=0
    
    # Get list of installed packages
    local installed_packages=()
    if [[ -d "$LOCAL_PACKAGES" ]]; then
        while IFS= read -r -d '' package_dir; do
            local package_name=$(basename "$package_dir")
            if [[ -f "$package_dir/.ubrew_metadata" ]]; then
                installed_packages+=("$package_name")
            fi
        done < <(find "$LOCAL_PACKAGES" -maxdepth 1 -type d -not -path "$LOCAL_PACKAGES" -print0)
    fi
    
    # Get list of packages in PATH config
    local configured_packages=()
    if [[ -f "$UBREW_PATH_FILE" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \#\ ubrew:\ (.+)$ ]]; then
                configured_packages+=("${BASH_REMATCH[1]}")
            fi
        done < "$UBREW_PATH_FILE"
    fi
    
    # Check for installed packages missing from PATH
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
            ((issues_found++))
            
            # Fix: Add to PATH
            local package_dir="$LOCAL_PACKAGES/$package"
            local bin_dir="$package_dir/bin"
            mkdir -p "$bin_dir"
            
            sed -i.bak "/^# === END UBREW MANAGED PATHS ===/i\\
export PATH=\"$bin_dir:\\\$PATH\" # ubrew: $package" "$UBREW_PATH_FILE"
            rm -f "$UBREW_PATH_FILE.bak"
            
            print_success "Fixed: Added '$package' to PATH"
            ((issues_fixed++))
        fi
    done
    
    # Check for PATH entries without corresponding packages
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
