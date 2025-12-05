# ubrew.sh - Ubuntu Package Manager

A simple, homebrew-like package manager for Ubuntu that automatically downloads, extracts, compiles, and manages packages locally.

## Features

- 📦 **Download & Extract**: Supports multiple archive formats (tar.gz, tar.bz2, tar.xz, zip, 7z)
- 🔍 **Auto-Detection**: Automatically detects project language and build system
- 🔨 **Auto-Compilation**: Compiles C, C++, C#, and Java projects with appropriate build tools
- �️ **Smart PATH Management**: Automatically adds/removes packages from PATH
- 🔧 **Self-Healing**: `verify` command detects and fixes PATH configuration issues
- 🔒 **Protected Configuration**: Clearly marked sections prevent accidental manual edits
- 📝 **Logging**: Tracks all operations in a log file
- 📦 **Local Storage**: All packages stored in `~/local_packages`
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

This command:
- Creates the necessary directories (`~/.ubrew` and `~/local_packages`)
- Adds ubrew to both `~/.bashrc` and `~/.zshrc`
- Configures PATH management
- Prompts you to reload your shell

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
6. ✅ Create metadata for tracking

**The package is immediately available in your current shell!**

### List Installed Packages

```bash
./ubrew.sh list
```

Output:
```
ℹ Installed packages:
  ✓ fzf                  [unknown] 2024-12-05T10:30:45Z
  ✓ jq                   [c] 2024-12-05T11:15:22Z
  Total: 2 package(s) installed
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
- ✅ Installed packages missing from PATH
- ✅ PATH entries for uninstalled packages
- ✅ Missing bin directories
- ✅ Proper file structure

Example output:
```
ℹ Verifying ubrew PATH configuration...
⚠ Package 'neovim' is installed but not in PATH
✓ Fixed: Added 'neovim' to PATH
⚠ PATH contains 'old-package' but package is not installed
✓ Fixed: Removed 'old-package' from PATH
ℹ Found 2 issue(s), fixed 2
✓ PATH verification complete!
```

**Use this if:**
- You manually deleted a package directory
- The PATH seems out of sync
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
    ├── package1/
    │   ├── .ubrew_metadata
    │   ├── bin/            # Executables (automatically added to PATH)
    │   └── ...
    └── package2/
        ├── .ubrew_metadata
        ├── bin/
        └── ...
```

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
- Missing packages in PATH
- Orphaned PATH entries
- Structural issues with the config file

### Package Appears Installed but Command Not Found

Run verify to ensure the package is properly registered:
```bash
./ubrew.sh verify
exec $SHELL  # Reload your shell
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
| `list` | Show all installed packages with metadata |
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
