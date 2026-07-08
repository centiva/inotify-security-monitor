detect_file() {

    local FILE="$1"
    local EVENT="$2"

    HASH=""

    if [ "$ENABLE_HASH" = "yes" ]
    then
        HASH=$(calculate_hash "$FILE")
    fi

}