#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CONFIG_FILE="$PROJECT_ROOT/tests/test-config.conf"

source "$PROJECT_ROOT/scripts/common.sh"


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
