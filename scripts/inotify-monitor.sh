#!/usr/bin/env bash

set -Eeuo pipefail


# ==========================================
# Inotify Security Monitor
# Real Time Monitor
# ==========================================


SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"


source "$SCRIPT_DIR/common.sh"



# ------------------------------------------
# Check dependencies
# ------------------------------------------

check_dependency inotifywait
check_dependency mail



# ------------------------------------------
# Prepare files
# ------------------------------------------

mkdir -p "$(dirname "$QUEUE_FILE")"

touch "$QUEUE_FILE"

touch "$LOG_FILE"



log_info "Starting Inotify Security Monitor"



# ------------------------------------------
# Monitor function
# ------------------------------------------

process_event()
{

    local DATE="$1"
    local TIME="$2"
    local FILE="$3"
    local EVENT="$4"


    if [ ! -f "$FILE" ]; then
        return
    fi


    if ! is_monitored_extension "$FILE"
    then
        return
    fi



    HASH=""

    if [ "${ENABLE_HASH:-no}" = "yes" ]
    then
        HASH=$(calculate_hash "$FILE")
    fi



    EVENT_LINE="$DATE $TIME|$EVENT|$FILE|$HASH"


    echo "$EVENT_LINE" >> "$QUEUE_FILE"



    log_info "$EVENT_LINE"



    if [ "${ENABLE_EMAIL:-no}" = "yes" ]
    then

        MESSAGE="
Security event detected

Host:
$(hostname)

Event:
$EVENT

File:
$FILE

SHA256:
$HASH
"

        send_email \
        "[SECURITY][$EVENT] $(hostname)" \
        "$MESSAGE"

    fi


}



# ------------------------------------------
# Start monitoring
# ------------------------------------------


inotifywait \
-m \
-r \
-e create \
-e modify \
-e moved_to \
-e attrib \
--format '%T %w%f %e' \
--timefmt '%F %T' \
"${WATCH_DIRS[@]}" |


while read DATE TIME FILE EVENT
do

    process_event \
    "$DATE" \
    "$TIME" \
    "$FILE" \
    "$EVENT"

done