#!/bin/bash

###############################################################################
# Syntax Checker for UBrew Scripts
# 
# Checks for syntax errors in all bash scripts in the current directory
# and all subdirectories.
###############################################################################

SCRIPT_DIR="$(dirname "$0")"
ERROR_FOUND=0
CHECKED_COUNT=0

echo "Checking syntax for all bash scripts..."
echo "========================================"

# Check the main ubrew.sh script
if [[ -f "$SCRIPT_DIR/ubrew.sh" ]]; then
    echo -n "Checking ubrew.sh... "
    if bash -n "$SCRIPT_DIR/ubrew.sh" 2>&1; then
        echo "✓ OK"
        ((CHECKED_COUNT++))
    else
        echo "✗ SYNTAX ERROR"
        ERROR_FOUND=1
        ((CHECKED_COUNT++))
    fi
fi

# Check all .sh files in subdirectories
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    relative_path="${file#$SCRIPT_DIR/}"
    
    echo -n "Checking $relative_path... "
    if bash -n "$file" 2>&1; then
        echo "✓ OK"
        ((CHECKED_COUNT++))
    else
        echo "✗ SYNTAX ERROR"
        ERROR_FOUND=1
        ((CHECKED_COUNT++))
    fi
done < <(find "$SCRIPT_DIR" -type f -name "*.sh" -not -name "ubrew.sh" -not -name "check_syntax.sh" -print0)

echo "========================================"
echo "Checked $CHECKED_COUNT script(s)"

if [[ $ERROR_FOUND -eq 0 ]]; then
    echo "✓ No syntax errors found!"
    exit 0
else
    echo "✗ Syntax errors detected. Please fix the errors above."
    exit 1
fi
