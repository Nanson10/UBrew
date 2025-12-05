#!/bin/bash

get_filename_from_url() {
    local url=$1
    basename "$url" | sed 's/?.*$//'
}

infer_package_name() {
    local input=$1
    local name=$(basename "$input" | sed -E 's/\.(tar\.(gz|bz2|xz)|zip|tgz|7z)$//')
    name=$(echo "$name" | sed -E 's/-v?[0-9]+(\.[0-9]+)*.*$//')
    echo "$name"
}

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
