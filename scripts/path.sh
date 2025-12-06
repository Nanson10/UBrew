#!/bin/bash

update_package_path() {
    local package_name=$1
    cmd_verify
    if grep -q "# ubrew: $package_name$" "$UBREW_PATH_FILE"; then
        print_success "Added $package_name to PATH"
        if [[ -n "$BASH_VERSION" ]] || [[ -n "$ZSH_VERSION" ]]; then
            source "$UBREW_PATH_FILE" 2>/dev/null || true
        fi
    fi
}

remove_package_path() {
    local package_name=$1
    cmd_verify >/dev/null 2>&1
    if ! grep -q "# ubrew: $package_name$" "$UBREW_PATH_FILE" 2>/dev/null; then
        print_success "Removed $package_name from PATH"
    fi
}

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
        if ! grep -q "^# === BEGIN UBREW MANAGED PATHS ===" "$UBREW_PATH_FILE"; then
            local temp_file="${UBREW_HOME}/temp_path_backup_$$_$(date +%s)"
            if grep -q "# ubrew:" "$UBREW_PATH_FILE"; then
                grep "# ubrew:" "$UBREW_PATH_FILE" > "$temp_file"
            fi
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
