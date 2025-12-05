#!/bin/bash

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
