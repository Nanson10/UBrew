# ubrew.sh - Ubuntu Package Manager

A simple, homebrew-like package manager for Ubuntu that automatically downloads, extracts, compiles, and manages packages locally.

## Features

- 📦 **Download & Extract**: Supports multiple archive formats (tar.gz, tar.bz2, tar.xz, zip, 7z).
- 🔍 **Auto-Detection**: Automatically detects project language and build system (Java, Go, Rust, C/C++, C#, Node.js, and more).
- 🔨 **Auto-Compilation**: Compiles C, C++, C#, and Java projects with the appropriate build tools (`make`, `cmake`, `dotnet`, `mvn`, `gradle`).
- 🛤️ **Reliable PATH Management**: Automatically keeps your `PATH` in sync. After adding or removing packages, `ubrew` verifies that all installed packages are in your `PATH` and removes any that are no longer installed.
- 🔧 **Automatic PATH Repair**: The `verify` command automatically adds missing package paths, removes orphaned entries, and interactively cleans up unused archives.
- 🔒 **Protected Configuration**: Clearly marked sections in the `PATH` file prevent accidental manual edits.
- 📝 **Logging**: Tracks all operations in a log file (`~/.ubrew/ubrew.log`).
- 💾 **Archive Caching**: Downloaded archives are cached to avoid re-downloading.
- 📦 **Local Storage**: All packages are stored in `~/local_packages/packages` with archives cached in `~/local_packages/archives`.
- 🎯 **Zero Manual Configuration**: Everything is automatic after `init`.

## Installation

### Prerequisites

For basic functionality:
```bash
sudo apt-get update
sudo apt-get install -y curl wget unzip p7zip-full
```

For language-specific compilation, install tools as needed:

**For C/C++:**
```bash
sudo apt-get install -y build-essential cmake
```

**For C#/.NET:**
```bash
sudo apt-get install -y dotnet-sdk
```

**For Java:**
```bash
sudo apt-get install -y default-jdk maven gradle
```

### Setup

1.  Make sure the script is executable:
    ```bash
    chmod +x ubrew.sh
    ```

2.  Initialize ubrew (this automatically adds it to your shell configuration):
    ```bash
    ./ubrew.sh init
    ```

3.  Reload your shell for the changes to take effect:
    ```bash
    exec $SHELL
    ```

**That's it!** The `init` command automatically adds `ubrew` to both `~/.bashrc` and `~/.zshrc`.

To later remove `ubrew` from your shell configuration:
```bash
./ubrew.sh uninit
```

## Usage

All commands are run via the main `ubrew.sh` script. After initialization, you can call `ubrew` from any directory.

### `init`

Initializes the `ubrew` environment.

```bash
./ubrew.sh init
```

To force re-initialization and clear all existing data (packages and archives), use the `--force` flag:

```bash
./ubrew.sh init --force
```

This command:
- Creates the necessary directories (`~/.ubrew`, `~/local_packages/packages`, `~/local_packages/archives`).
- Adds `ubrew` to both `~/.bashrc` and `~/.zshrc`.
- Configures the `PATH` management file.
- Prompts you to reload your shell.

If `ubrew` is already initialized, the command will exit with a warning. Use the `--force` flag if you intend to start fresh.

### `add <URL_or_FilePath>`

Downloads, extracts, and compiles a package from a URL or a local file path.

```bash
# From a URL
./ubrew.sh add <URL>

# From a local file
./ubrew.sh add /path/to/archive.tar.gz
```

After a successful installation, `ubrew` automatically runs a verification check to add the new package's binary directory to your `PATH`.

**Examples:**
- **Go**: `ubrew.sh add https://golang.org/dl/go1.17.5.linux-amd64.tar.gz`
- **Java/Maven**: `ubrew.sh add https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz`
- **Node**: `ubrew.sh add https://nodejs.org/dist/v16.13.1/node-v16.13.1-linux-x64.tar.gz`

### `remove <package_name>`

Removes a package.

```bash
./ubrew.sh remove <package_name>
```

After removing the package, `ubrew` automatically runs a verification check to remove the package's directory from your `PATH`.

### `list`

Lists all installed packages.

```bash
./ubrew.sh list
```

To see the full installation path for each package, use the `-p` flag:

```bash
./ubrew.sh list -p
```

### `verify`

Manually verifies the `ubrew` environment. This is the interactive version of the verification that runs automatically after `add` and `remove`.

```bash
./ubrew.sh verify
```

This command performs the following actions:
- **Adds Missing Paths**: Scans all installed packages and adds `PATH` entries for any that are missing.
- **Removes Orphaned Paths**: Removes `PATH` entries for packages that are no longer installed.
- **Cleans Orphaned Archives (Interactive)**: Prompts you to remove any downloaded archives for packages that are no longer installed.

### `uninit`

Removes `ubrew` from your shell configuration files (`.bashrc` and `.zshrc`).

```bash
./ubrew.sh uninit
```

This does **not** remove the `~/local_packages` or `~/.ubrew` directories. You can remove them manually if you wish.

### `help`

Displays the help message.

```bash
./ubrew.sh help
```

## How It Works

### Language Detection

`ubrew` detects the language or build system of a package by looking for specific files in the extracted directory:

- **Java**: `pom.xml` (Maven) or `build.gradle` (Gradle)
- **Go**: `go.mod`
- **Rust**: `Cargo.toml`
- **Python**: `setup.py` or `pyproject.toml`
- **Node.js**: `package.json`
- **C/C++**: `Makefile`, `configure` script, or `CMakeLists.txt`
- **C#**: `.csproj` files

### Compilation

Based on the detected language, `ubrew` runs the appropriate build command:

- **make**: `make`
- **cmake**: `cmake .. && make`
- **csharp**: `dotnet build -c Release`
- **java**: `mvn clean package -DskipTests` or `gradle build -x test`

For other languages like Go, Python, or Node, no compilation step is taken, as they are typically pre-compiled or script-based.

### PATH Management

`ubrew` manages all `PATH` exports in a single file: `~/.ubrew/path.conf`. This file is sourced by your `.bashrc` or `.zshrc`.

The `verify` command ensures this file is always correct by:
1.  Finding all installed packages in `~/local_packages/packages`.
2.  Checking if each one has a corresponding `export PATH` line in `path.conf`.
3.  Adding lines for missing packages and removing lines for uninstalled ones.

The binary directory is inferred (`bin`, `target`, or the root of the package).

## License

This project is licensed under the MIT License.