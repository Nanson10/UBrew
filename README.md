# ubrew.sh - Ubuntu Package Manager

A simple, homebrew-like package manager for Ubuntu that automatically downloads, extracts, compiles, and manages packages locally.

## Features

- 📦 **Download & Extract**: Supports multiple archive formats (tar.gz, tar.bz2, tar.xz, zip, 7z)
- 🔍 **Auto-Detection**: Automatically detects project language and build system
- 🔨 **Auto-Compilation**: Compiles C, C++, C#, and Java projects with appropriate build tools
- 📍 **PATH Management**: Automatically manages your system PATH
- 📝 **Logging**: Tracks all operations in a log file
- 📦 **Local Storage**: All packages stored in `~/local_packages`

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
5. ✅ Update your PATH
6. ✅ Create metadata for tracking

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
│   ├── path.conf          # PATH configuration (sourced in shell RC)
│   └── ubrew.log          # Activity log
└── local_packages/
    ├── package1/
    │   ├── .ubrew_metadata
    │   ├── bin/            # Executables added to PATH
    │   └── ...
    └── package2/
        ├── .ubrew_metadata
        ├── bin/
        └── ...
```

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

Make sure you've sourced the PATH configuration in your shell RC file and reloaded it:
```bash
source ~/.bashrc
# or
source ~/.zshrc
```

### Can't Find Package Executable

Some packages may not provide executables in standard locations. Check the package directory:
```bash
ls -la ~/local_packages/<package-name>/
```

## Configuration Files

**`~/.ubrew/path.conf`** - Contains PATH export commands for all installed packages
**`~/.ubrew/ubrew.log`** - Complete activity log

## Limitations

- ⚠️ **No Dependency Resolution**: Packages must be self-contained or have dependencies pre-installed
- ⚠️ **No Version Management**: Installing a package with the same name overwrites the previous version
- ⚠️ **Limited to Supported Languages**: Other languages are extracted but not compiled

## Contributing

Feel free to extend this script with:
- Additional language support
- Dependency resolution
- Version management
- Package registry
- Rollback functionality

## License

MIT License - Feel free to use and modify!
