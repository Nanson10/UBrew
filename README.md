# ubrew.sh - Ubuntu Package Manager

A simple, homebrew-like package manager for Ubuntu that automatically downloads, extracts, compiles, and manages packages locally.

## Features

- 📦 **Download & Extract**: Supports multiple archive formats (tar.gz, tar.bz2, tar.xz, zip, 7z)
- 🔍 **Auto-Detection**: Automatically detects project language and build system
- 🔨 **Auto-Compilation**: Compiles C, C++, C#, and Java projects with appropriate build tools
- 🛤️ **Smart PATH Management**: Automatically adds/removes packages from PATH
- 🔧 **Configuration Repair**: `verify` command detects and removes orphaned PATH entries and archives
- 🔒 **Protected Configuration**: Clearly marked sections prevent accidental manual edits
- 📝 **Logging**: Tracks all operations in a log file
- 💾 **Archive Caching**: Downloaded archives are cached to avoid re-downloading
- 📦 **Local Storage**: All packages stored in `~/local_packages/packages` with archives cached in `~/local_packages/archives`
- 🎯 **Zero Manual Configuration**: Everything is automatic after `init`

## Installation

### Prerequisites

For basic functionality:
```bash
sudo apt-get update
sudo apt-get install curl wget unzip
```

For language support, install compilers as needed:

**For C/C++:**
```bash
sudo apt-get install build-essential cmake
```

**For C#/.NET:**
```bash
sudo apt-get install dotnet-sdk
```

**For Java:**
```bash
sudo apt-get install default-jdk maven gradle
```

### Setup

1. Make sure the script is executable:
```bash
chmod +x ubrew.sh
```

2. Initialize ubrew (this automatically adds it to your shell configuration):
```bash
./ubrew.sh init
```

3. Reload your shell:
```bash
exec $SHELL
```

**That's it!** The `init` command automatically adds ubrew to both `~/.bashrc` and `~/.zshrc`.

To later remove ubrew from your shell configuration:
```bash
./ubrew.sh uninit
```

## Usage

### Initialize ubrew

```bash
./ubrew.sh init
```

To force re-initialization and clear all existing data (packages and archives), use the `--force` flag:

```bash
./ubrew.sh init --force
```

This command:
- Creates the necessary directories (`~/.ubrew`, `~/local_packages/packages`, `~/local_packages/archives`).
- Adds ubrew to both `~/.bashrc` and `~/.zshrc`.
- Configures PATH management.
- Prompts you to reload your shell.

If `ubrew` is already initialized, the command will exit with a warning. Use the `--force` flag if you intend to start fresh.

After initialization, you can call ubrew from anywhere and all installed packages will be available in your PATH.

### Add a Package

```bash
./ubrew.sh add <URL>
```

Examples:
```bash
# Download from GitHub release
./ubrew.sh add https://github.com/junegunn/fzf/releases/download/0.30.0/fzf-0.30.0-linux_amd64.tar.gz

# Download from project repository
./ubrew.sh add https://github.com/stedolan/jq/releases/download/jq-1.6/jq-1.6.tar.gz
```

The script will:
1. ✅ Download the archive
2. ✅ Extract to `~/local_packages/<package-name>`
3. ✅ Detect the programming language
4. ✅ Compile if necessary
5. ✅ **Automatically add to your PATH**

**The package is immediately available in your current shell!**

### List Installed Packages

```bash
./ubrew.sh list
```

Output:
```
Installed packages:
- fzf
- jq
- neovim
```

### Remove a Package

```bash
./ubrew.sh remove <package-name>
```

Example:
```bash
./ubrew.sh remove fzf
```

**The package is automatically removed from your PATH!**

### Verify PATH Configuration

```bash
./ubrew.sh verify
```

This command checks and fixes:
- ✅ PATH entries for uninstalled packages (orphaned entries)
- ✅ Orphaned archives without installed packages
- ✅ Proper file structure and configuration

Example output:
```
ℹ Verifying PATH configuration...
⚠ Orphaned PATH entry: old-package
⚠ Orphaned archive: some-package-1.0.tar.gz
Remove orphaned archive 'some-package-1.0.tar.gz'? [y/N]: y
ℹ Archive removed.
✓ PATH verification complete.
```

**Use this if:**
- You manually deleted a package directory
- The PATH seems out of sync
- You want to clean up orphaned archives
- You want to ensure everything is properly configured

### Uninstall ubrew

```bash
./ubrew.sh uninit
```

This removes ubrew from your shell configuration files (`~/.bashrc` and `~/.zshrc`).

### Get Help

```bash
./ubrew.sh help
```

## How It Works

### Language Detection

The script detects project types by looking for:

- **Java**: `pom.xml` (Maven) or `build.gradle` (Gradle)
- **C/C++**: `CMakeLists.txt` (CMake), `Makefile`, or `.cpp/.c` files
- **C#**: `.csproj` files
- **Python**: `setup.py` or `pyproject.toml`
- **Node.js**: `package.json`
- **Go**: `go.mod`
- **Rust**: `Cargo.toml`

### Compilation

Supported compilers:

| Language | Build System | Notes |
|----------|-------------|-------|
| C | Make, CMake | Requires gcc |
| C++ | Make, CMake | Requires g++, optionally cmake |
| C# | .NET | Requires dotnet SDK |
| Java | Maven, Gradle | Requires JDK and build tool |

### Directory Structure

```
~/
├── .ubrew/
│   ├── path.conf          # PATH configuration (auto-managed, DO NOT EDIT manually)
│   └── ubrew.log          # Activity log
└── local_packages/
    ├── archives/          # Downloaded archives (cached for reuse)
    │   ├── package1.tar.gz
    │   └── package2.zip
    ├── package1/
    │   ├── bin/            # Executables (automatically added to PATH)
    │   ├── src/
    │   └── ...
    └── package2/
        ├── bin/
        └── ...
```

**Note**: `.ubrew_metadata` file support is planned for future versions to track installation details.

### PATH Configuration File

The `~/.ubrew/path.conf` file has a protected section:

```bash
#!/bin/bash
# ubrew PATH configuration file
# 
# WARNING: DO NOT MANUALLY EDIT THE SECTION BETWEEN THE MARKERS BELOW!
# This section is automatically managed by ubrew.sh
# Manual edits will be overwritten when packages are added or removed.
#
# === BEGIN UBREW MANAGED PATHS ===
export PATH="/home/user/local_packages/fzf/bin:$PATH" # ubrew: fzf
export PATH="/home/user/local_packages/jq/bin:$PATH" # ubrew: jq
# === END UBREW MANAGED PATHS ===
#
# You may add your own custom PATH modifications below this line:
# (Your custom exports go here and will never be touched by ubrew)
```

**Key Points:**
- ⚠️ **Don't edit the section between the markers** - it's auto-managed
- ✅ **Safe to add your own exports below the markers**
- 🔧 **Run `ubrew.sh verify` to fix any corruption**

## Troubleshooting

### Package Won't Install

Check the log file for details:
```bash
cat ~/.ubrew/ubrew.log
```

### Compilation Failed

Install the required build tools for your language:
- **C/C++**: `sudo apt-get install build-essential cmake`
- **C#**: `sudo apt-get install dotnet-sdk`
- **Java**: `sudo apt-get install default-jdk maven gradle`

### PATH Not Updated

1. First, try running verify to fix any issues:
```bash
./ubrew.sh verify
```

2. If that doesn't help, make sure you've initialized ubrew:
```bash
./ubrew.sh init
exec $SHELL
```

3. Verify the path.conf is being sourced in your shell RC file:
```bash
grep "ubrew" ~/.zshrc  # or ~/.bashrc
```

### PATH Configuration Corrupted

If you accidentally edited the protected section or something went wrong:
```bash
./ubrew.sh verify
```

This will automatically detect and fix:
- Orphaned PATH entries (packages that no longer exist)
- Structural issues with the config file
- Prompt for removal of orphaned archives

**Note**: If a package is installed but not in PATH, you may need to remove and re-add it:
```bash
./ubrew.sh remove <package-name>
./ubrew.sh add <package-url>
```

### Package Appears Installed but Command Not Found

The package directory exists but the command isn't available. This could mean:

1. **PATH not updated**: Reload your shell to apply PATH changes
```bash
source ~/.ubrew/path.conf
# or
exec $SHELL
```

2. **Package has no bin directory**: Some packages may need manual setup
```bash
ls -la ~/local_packages/<package-name>/
```

3. **Wrong executable location**: You may need to create a bin directory and symlink:
```bash
mkdir -p ~/local_packages/<package-name>/bin
ln -s ~/local_packages/<package-name>/path/to/executable ~/local_packages/<package-name>/bin/
```

### Can't Find Package Executable

Some packages may not provide executables in standard locations. Check the package directory:
```bash
ls -la ~/local_packages/<package-name>/
```

You may need to manually symlink executables to the bin directory:
```bash
ln -s ~/local_packages/<package-name>/path/to/executable ~/local_packages/<package-name>/bin/
```

## Configuration Files

**`~/.ubrew/path.conf`** - Contains PATH export commands for all installed packages. **DO NOT manually edit the section between the markers!** The file has a protected auto-managed section and a safe zone for your custom PATH additions.

**`~/.ubrew/ubrew.log`** - Complete activity log with timestamps for all operations.

## Commands Reference

| Command | Description |
|---------|-------------|
| `init` | Initialize ubrew and add to shell configuration |
| `uninit` | Remove ubrew from shell configuration |
| `add <url>` | Download, extract, compile, and install a package |
| `remove <name>` | Remove an installed package |
| `list` | Show all installed packages |
| `verify` | Check and repair PATH configuration |
| `help` | Display help information |

## Best Practices

✅ **DO:**
- Run `./ubrew.sh init` once after downloading the script
- Use `./ubrew.sh verify` if you suspect PATH issues
- Add custom PATH exports below the protected section in path.conf
- Check the log file if something goes wrong

❌ **DON'T:**
- Edit the protected section in `~/.ubrew/path.conf`
- Manually delete packages from `~/local_packages` without running `remove`
- Move package directories after installation

If you do accidentally mess things up, just run `./ubrew.sh verify` to fix it!

## Limitations

- ⚠️ **No Dependency Resolution**: Packages must be self-contained or have dependencies pre-installed
- ⚠️ **No Version Management**: Installing a package with the same name overwrites the previous version
- ⚠️ **Limited to Supported Languages**: Other languages are extracted but not compiled

## Future Enhancements

Potential features for future versions:
- Dependency resolution
- Multiple version support
- Package registry/database
- Rollback functionality  
- Update checking
- Binary-only package support
- Custom build script support

## Contributing

Feel free to extend this script with:
- Additional language support
- Better compilation detection
- Enhanced error handling
- Package templates
- Integration with other package managers

## License

MIT License - Feel free to use and modify!

---

## Quick Start Example

```bash
# 1. Make executable
chmod +x ubrew.sh

# 2. Initialize
./ubrew.sh init
exec $SHELL

# 3. Install a package
./ubrew.sh add https://github.com/user/project/archive/v1.0.tar.gz

# 4. Use it immediately (already in PATH!)
project-command --version

# 5. List installed packages
./ubrew.sh list

# 6. Verify everything is good
./ubrew.sh verify

# 7. Remove when done
./ubrew.sh remove project
```

That's it! Enjoy your homebrew-like experience on Ubuntu! 🎉

---

## Technical Deep Dive

This section provides detailed technical documentation for developers and contributors who want to understand the internal architecture and implementation of ubrew.

### Architecture Overview

ubrew follows a modular architecture where the main script (`ubrew.sh`) acts as a command dispatcher and orchestrator, while individual functionality is encapsulated in separate shell script modules located in the `scripts/` directory.

```
ubrew.sh (Main Entry Point)
    ├── Sources utility modules
    ├── Sources command modules
    └── Dispatches to appropriate command handler

scripts/
    ├── Command Handlers (cmd_*.sh)
    ├── Core Utilities (utils.sh, path.sh, etc.)
    └── Specialized Functions (compile.sh, download_and_extract.sh)
```

### Main Script: `ubrew.sh`

**Purpose**: Entry point and command dispatcher for the ubrew package manager.

**Key Responsibilities**:
- Define global environment variables and configuration paths
- Source all required script modules
- Parse command-line arguments
- Route commands to appropriate handler functions
- Provide centralized error handling for unknown commands

**Environment Variables**:
```bash
UBREW_HOME="${HOME}/.ubrew"              # Configuration directory
LOCAL_PACKAGES="${HOME}/local_packages"  # Package installation directory
ARCHIVES_DIR="${LOCAL_PACKAGES}/archives" # Downloaded archives storage
UBREW_TEMP="${UBREW_HOME}/temp"          # Temporary files directory
UBREW_PATH_FILE="${UBREW_HOME}/path.conf" # PATH configuration file
UBREW_LOG="${UBREW_HOME}/ubrew.log"      # Activity log file
```

**Color Codes**:
```bash
RED, GREEN, YELLOW, BLUE, NC (No Color)  # ANSI escape codes for colored output
```

**Command Routing**:
The main function uses a case statement to dispatch commands to their respective handlers:
- `init` → `cmd_init()`
- `uninit` → `cmd_uninit()`
- `add` → `cmd_add()`
- `remove` → `cmd_remove()`
- `list` → `cmd_list()`
- `verify` → `cmd_verify()`
- `help` → `cmd_help()`

---

### Core Utility Scripts

#### `scripts/utils.sh`

**Purpose**: Provides helper functions for package name inference, language detection, and build tool checking.

**Functions**:

1. **`get_filename_from_url(url)`**
   - Extracts the filename from a URL
   - Removes query parameters using sed
   - Returns: Clean filename string

2. **`infer_package_name(filename)`**
   - Derives package name from archive filename
   - Strips common archive extensions (`.tar.gz`, `.tar.bz2`, `.tar.xz`, `.zip`, `.tgz`, `.7z`)
   - Removes version numbers using regex pattern matching
   - Returns: Clean package name suitable for directory naming

3. **`detect_language(directory)`**
   - Analyzes directory contents to determine project language/build system
   - Uses a hierarchical detection strategy:
     - **Priority 1**: Build system config files (pom.xml, build.gradle, CMakeLists.txt, etc.)
     - **Priority 2**: Language-specific package files (go.mod, Cargo.toml, package.json, etc.)
     - **Priority 3**: Source file extensions (.java, .cpp, .c, .cs)
   - Returns: Language identifier string (java, cpp, c, python, node, go, rust, csharp, make, cmake, unknown)

4. **`check_build_tools(language)`**
   - Validates presence of required compilation tools for a given language
   - Checks using `command -v` for tool availability
   - Returns: 0 if all tools present, 1 if missing tools
   - Languages checked:
     - **C/C++/Make**: gcc, g++, make
     - **CMake**: cmake, gcc, make
     - **C#**: dotnet
     - **Java**: javac

---

#### `scripts/print.sh`

**Purpose**: Provides consistent, colorized output functions for user feedback.

**Functions**:

1. **`print_info(message)`** - Blue ℹ icon for informational messages
2. **`print_success(message)`** - Green ✓ icon for success messages
3. **`print_error(message)`** - Red ✗ icon for error messages
4. **`print_warning(message)`** - Yellow ⚠ icon for warning messages

**Implementation Details**:
- Uses `echo -e` to interpret ANSI escape codes
- Automatically includes Unicode symbols for better UX
- Color codes are sourced from main script's global variables

---

#### `scripts/log.sh`

**Purpose**: Provides structured logging functionality with timestamps.

**Function**:

**`log(level, message)`**
- **Parameters**:
  - `level`: Log level (e.g., INFO, ERROR, WARNING)
  - `message`: Log message content
- **Format**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] message`
- **Output**: Appends to `$UBREW_LOG` file
- **Use Cases**: Tracking package operations, debugging, audit trail

---

#### `scripts/path.sh`

**Purpose**: Manages PATH configuration file and package PATH entries.

**Functions**:

1. **`update_package_path(package_name, package_dir)`**
   - Adds a package to PATH by running verification
   - Automatically sources the updated path.conf in current shell
   - Silently runs `cmd_verify` to handle the actual PATH update
   - Provides user feedback when package is added to PATH

2. **`remove_package_path(package_name)`**
   - Removes package PATH entries by delegating to verify
   - Uses `cmd_verify` to clean up the PATH configuration
   - Provides confirmation feedback to user

3. **`ensure_path_file_structure()`**
   - Creates or repairs the path.conf file structure
   - Implements the protected section markers:
     ```
     # === BEGIN UBREW MANAGED PATHS ===
     (managed content)
     # === END UBREW MANAGED PATHS ===
     ```
   - Migrates old format path files to new protected structure
   - Preserves existing ubrew-managed entries during migration
   - Creates backup during migration process

**File Structure**:
The path.conf file uses a three-section design:
1. **Header**: Warning about manual editing
2. **Managed Section**: Between markers, auto-managed by ubrew
3. **User Section**: Below markers, safe for manual edits

---

#### `scripts/initialize.sh`

**Purpose**: Sets up the ubrew environment and directory structure.

**Function**:

**`initialize()`**
- Creates required directories:
  - `~/.ubrew` - Configuration directory
  - `~/local_packages` - Package installation root
  - `~/local_packages/archives` - Archive storage
  - `~/.ubrew/temp` - Temporary files
- Initializes `path.conf` with protected structure if it doesn't exist
- Cleans up old temporary files (older than 1 day)
- Called automatically by `cmd_init` and implicitly by other commands

---

#### `scripts/download_and_extract.sh`

**Purpose**: Handles downloading archives and extracting them to package directories.

**Function**:

**`download_and_extract(url, dest)`**

**Parameters**:
- `url`: URL to download archive from
- `dest`: Destination directory for extracted package

**Process**:
1. **Download Phase**:
   - Extracts filename from URL
   - Checks if archive already exists in `$ARCHIVES_DIR`
   - Downloads using `wget -q` if not cached
   - Provides download progress feedback

2. **Extraction Phase**:
   - Detects archive format by extension and magic bytes
   - Supported formats:
     - `.tar.gz`, `.tgz` → `tar -xzf`
     - `.tar.bz2` → `tar -xjf`
     - `.tar.xz` → `tar -xJf`
     - `.zip` → `unzip`
     - `.7z` → `7z`
   - Uses `--strip-components=1` for tarballs to flatten single-directory archives
   - Fallback: Uses `file` command for format detection if extension is unclear
   - For zip files: Automatically flattens if archive contains single top-level directory

3. **Error Handling**:
   - Cleans up partial downloads on failure
   - Validates extraction success
   - Returns non-zero exit code on errors

**Special Features**:
- Archive caching: Won't re-download if file exists
- Smart directory flattening for better package structure
- Graceful fallback to format detection via `file` command

---

#### `scripts/compile.sh`

**Purpose**: Handles compilation of packages based on detected language and build system.

**Functions**:

1. **`compile_package(package_dir, language)`**
   - Main compilation dispatcher
   - Routes to language-specific compilation function
   - Returns 0 for successful compilation or no-compilation-needed cases
   - Returns 1 for compilation failures

2. **`compile_make(package_dir)`**
   - Compiles C/C++ projects using Make
   - Validates Makefile presence
   - Runs `make` and pipes output to log
   - Executes in package directory

3. **`compile_cmake(package_dir)`**
   - Compiles CMake-based projects
   - Creates `build/` subdirectory
   - Runs `cmake ..` followed by `make`
   - Uses out-of-source build pattern
   - Logs both cmake and make output

4. **`compile_csharp(package_dir)`**
   - Compiles .NET/C# projects
   - Runs `dotnet build -c Release`
   - Creates optimized release builds
   - Logs build output

5. **`compile_java(package_dir)`**
   - Compiles Java projects with Maven or Gradle
   - Auto-detects build system (pom.xml vs build.gradle)
   - Maven: `mvn clean package -DskipTests`
   - Gradle: `gradle build -x test`
   - Skips tests for faster builds

**Compilation Strategy**:
- All compilation happens in the package directory
- Output is captured and logged for debugging
- Non-zero exit codes propagate to caller
- Languages without compilation (Python, Node.js, etc.) return success immediately

---

### Command Handler Scripts

#### `scripts/cmd_init.sh`

**Purpose**: Initialize ubrew and prepare shell integration.

**Function**:

**`cmd_init()`**
- Calls `initialize()` to set up directory structure
- Provides success feedback to user
- Note: Shell integration should be done manually or via separate script
  (The README mentions auto-adding to shell config, but implementation delegates to user)

---

#### `scripts/cmd_uninit.sh`

**Purpose**: Remove ubrew from shell configuration files.

**Function**:

**`cmd_uninit()`**
- Removes ubrew-related lines from `~/.bashrc`
- Removes ubrew-related lines from `~/.zshrc`
- Uses `sed -i ''` for macOS compatibility
- Searches for lines containing `ubrew.sh`
- Provides confirmation feedback

**Note**: Uses `2>/dev/null` to suppress errors if files don't exist.

---

#### `scripts/cmd_add.sh`

**Purpose**: Download, extract, compile, and install a package from a URL.

**Function**:

**`cmd_add(url)`**

**Process Flow**:
1. **URL Validation**: Ensures URL is provided
2. **Name Inference**: 
   - Extracts filename from URL
   - Infers clean package name
   - Determines package directory path
3. **Download & Extract**:
   - Calls `download_and_extract(url, package_dir)`
   - Handles extraction failures with error reporting
4. **Language Detection**:
   - Analyzes extracted package contents
   - Detects programming language/build system
5. **Compilation**:
   - Calls `compile_package(package_dir, language)`
   - On failure: Prompts user to remove package
   - Cleans up package directory and archive if user confirms
6. **PATH Integration**:
   - Calls `update_package_path(package_name)`
   - Makes package immediately available
7. **Logging**:
   - Records installation with INFO level log
   - Includes package name and source URL

**Error Handling**:
- Download failure → Clean exit with error message
- Compilation failure → Offer cleanup, warn but allow keeping
- User can choose to keep partially-installed packages

---

#### `scripts/cmd_remove.sh`

**Purpose**: Uninstall a package and clean up associated files.

**Function**:

**`cmd_remove(package_name)`**

**Process Flow**:
1. **Validation**: Ensures package name is provided
2. **Existence Check**: Verifies package directory exists
3. **Removal**:
   - Deletes package directory: `rm -rf $package_dir`
   - Deletes associated archives: `rm -f $ARCHIVES_DIR/${package_name}.*`
4. **PATH Cleanup**: Calls `remove_package_path(package_name)`
5. **Logging**: Records removal with INFO level log
6. **Feedback**: Confirms successful removal

**Safety Features**:
- Checks package existence before attempting removal
- Provides clear error if package not found
- Cleans both package files and cached archives

---

#### `scripts/cmd_list.sh`

**Purpose**: Display all installed packages.

**Function**:

**`cmd_list()`**

**Process**:
1. Prints header: "Installed packages:"
2. Iterates through `$LOCAL_PACKAGES/*` directories
3. For each directory:
   - Skips non-directory entries
   - Extracts package name using `basename`
   - Displays package name with bullet point

**Output Format**:
```
Installed packages:
- package1
- package2
- package3
```

**Note**: Current implementation is simple. Could be enhanced to show:
- Installation date (from metadata)
- Language/version (from `.ubrew_metadata` file)
- Package size
- PATH status

---

#### `scripts/cmd_verify.sh`

**Purpose**: Verify and repair PATH configuration, ensuring consistency between installed packages and PATH entries.

**Function**:

**`cmd_verify()`**

**Process Flow**:
1. **Initialization**:
   - Displays verification message
   - Calls `ensure_path_file_structure()` to validate/repair file structure

2. **Package Validation**:
   - Reads current PATH configuration file
   - Identifies packages referenced in PATH
   - Checks if corresponding package directories exist
   - Builds lists of valid packages and orphaned PATH entries

3. **Orphan Cleanup**:
   - Identifies PATH entries for non-existent packages
   - Removes orphaned entries automatically
   - Provides warning feedback for each removal

4. **Archive Cleanup**:
   - Scans `$ARCHIVES_DIR` for cached archives
   - Identifies archives without corresponding installed packages
   - Prompts user for confirmation before removing orphaned archives
   - User can choose to keep or delete each orphaned archive

5. **Completion**:
   - Displays success message
   - PATH configuration is now consistent

**Use Cases**:
- After manual package directory deletion
- Corrupted path.conf file
- Migrating from old ubrew version
- Regular maintenance/health check

**Smart Features**:
- Non-destructive: Only removes confirmed orphans
- Interactive: Prompts for archive removal
- Automatic: Fixes PATH entries without user intervention
- Idempotent: Safe to run multiple times

---

#### `scripts/cmd_help.sh`

**Purpose**: Display comprehensive help information.

**Function**:

**`cmd_help()`**

**Content Sections**:
1. **Title**: ubrew.sh branding
2. **Usage**: Basic syntax
3. **Commands**: Detailed command list with descriptions
4. **Examples**: Common usage patterns
5. **Configuration**: File paths and locations
6. **Supported Languages**: List of auto-detected languages
7. **Features**: Key capabilities using checkmarks

**Implementation**:
- Uses heredoc (`cat <<EOF`) for multi-line output
- Incorporates color variables for visual clarity
- Dynamically includes current configuration paths
- Provides context-aware information

---

### Data Flow Diagram

```
User Command
    ↓
ubrew.sh (main dispatcher)
    ↓
Command Handler (cmd_*.sh)
    ↓
    ├─→ download_and_extract.sh → Archives packages
    ├─→ utils.sh → detect_language()
    ├─→ compile.sh → Builds package
    ├─→ path.sh → Updates PATH
    └─→ log.sh → Records activity
    ↓
Success/Failure Response
```

---

### File System Layout

```
~/.ubrew/
├── path.conf          # PATH configuration with protected sections
├── ubrew.log          # Activity log with timestamps
└── temp/              # Temporary files (auto-cleaned)

~/local_packages/
├── archives/          # Downloaded archives (cached)
│   ├── package1.tar.gz
│   └── package2.zip
├── package1/          # Installed package
│   ├── .ubrew_metadata (planned)
│   ├── bin/
│   ├── src/
│   └── ...
└── package2/
    └── ...
```

---

### Extension Points for Contributors

**Adding New Language Support**:
1. Add detection logic in `utils.sh::detect_language()`
2. Add build tool checks in `utils.sh::check_build_tools()`
3. Add compilation function in `compile.sh::compile_<language>()`
4. Add case in `compile.sh::compile_package()`
5. Update README documentation

**Adding New Commands**:
1. Create `scripts/cmd_<name>.sh` with `cmd_<name>()` function
2. Source the script in `ubrew.sh`
3. Add case statement entry in `ubrew.sh::main()`
4. Update `cmd_help.sh` documentation

**Improving Path Management**:
- Current implementation uses simple grep/sed
- Could be enhanced with proper parsing
- Consider using associative arrays for package tracking
- Add metadata file support for advanced features

**Metadata System** (Planned):
- `.ubrew_metadata` file in each package directory
- Store: installation date, URL, version, language, build status
- Enable: version tracking, update checking, rollback

---

### Testing Recommendations

**Unit Testing** (Manual):
```bash
# Test each utility function
source scripts/utils.sh
detect_language /path/to/test/project

# Test package name inference
infer_package_name "project-v1.2.3.tar.gz"
```

**Integration Testing**:
```bash
# Test full workflow
./ubrew.sh init
./ubrew.sh add <test-package-url>
./ubrew.sh list
./ubrew.sh verify
./ubrew.sh remove <package-name>
```

**Edge Cases to Test**:
- Archives without version numbers
- Multi-directory archives
- Mixed language projects
- Missing build tools
- Corrupted downloads
- Manual path.conf edits
- Orphaned archives

---

### Performance Considerations

- **Archive Caching**: Downloads are cached to avoid re-downloading
- **Temp Cleanup**: Old temp files cleaned during initialization
- **Lazy Loading**: Scripts sourced once at startup
- **Background Compilation**: Consider adding background compilation option
- **Parallel Operations**: Currently sequential, could parallelize downloads

### Security Considerations

- **URL Validation**: Consider adding URL whitelist/validation
- **Checksum Verification**: Future enhancement for archive integrity
- **Safe Extraction**: Extraction happens in controlled directories
- **Log Permissions**: Logs may contain sensitive paths
- **Shell Injection**: Current use of eval/sourcing needs review for production use

---

### Known Limitations & Future Work

1. **No Dependency Resolution**: Packages must be self-contained
2. **No Version Management**: Can't install multiple versions
3. **Limited Binary Support**: Focuses on source compilation
4. **No Rollback**: Can't undo failed installations easily
5. **Shell-Specific**: Bash/Zsh only, no fish/PowerShell support
6. **Platform-Specific**: Designed for Ubuntu/Linux, limited macOS support

**Planned Enhancements**:
- Package registry/database integration
- Dependency graph resolution
- Version pinning and multi-version support
- Binary package support
- Automated testing framework
- Package update checking
- Installation snapshots for rollback

---

This technical documentation should help developers understand the codebase and contribute effectively to ubrew!