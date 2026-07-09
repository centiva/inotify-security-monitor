#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


# Test configuration
WATCH_EXTENSIONS=(
    "php"
    "phtml"
    "sh"
    "js"
)

EXCLUDE_DIRS=()
EXCLUDE_FILES=()
EXCLUDE_EXTENSIONS=()

EXCLUDE_DIR_PATTERNS=(
    "*/cache/*"
    "*/vendor/*"
)

EXCLUDE_FILE_PATTERNS=()
EXCLUDE_PATH_PATTERNS=()

source "$PROJECT_ROOT/scripts/common.sh"

EXCLUDE_DIR_PATTERNS=(
    "*/cache/*"
    "*/vendor/*"
)

build_filter_lists


FILES=(
"/tmp/test.php"
"/tmp/image.jpg"
"/tmp/cache/index.php"
"/tmp/vendor/test.php"
)

for FILE in "${FILES[@]}"
do

    if should_monitor_file "$FILE"
    then
        echo "PROCESS: $FILE"
    else
        echo "IGNORE : $FILE ($FILTER_REASON)"
    fi

done
