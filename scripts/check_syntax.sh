#!/bin/bash
# Utility script to check for syntax errors in all scripts in the scripts/ directory

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="${SCRIPT_DIR%/scripts}"
ERROR_FOUND=0

for file in "$SCRIPT_DIR"/*.sh; do
    if ! bash -n "$file"; then
        echo "Syntax error in: $file"
        ERROR_FOUND=1
    fi
done

if [ $ERROR_FOUND -eq 0 ]; then
    echo "No syntax errors found in scripts."
    exit 0
else
    echo "Syntax errors detected."
    exit 1
fi
