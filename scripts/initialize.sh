#!/bin/bash

initialize() {
    mkdir -p "$UBREW_HOME"
    mkdir -p "$LOCAL_PACKAGES"
    mkdir -p "$ARCHIVES_DIR"
    mkdir -p "$UBREW_TEMP"
    find "$UBREW_TEMP" -type f -mtime +1 -delete 2>/dev/null || true
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
