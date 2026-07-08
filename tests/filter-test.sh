#!/usr/bin/env bash

source scripts/common.sh

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