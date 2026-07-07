#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_FILE="$PROJECT_DIR/config/inotify-security-monitor.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"


log()
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

email_rate_limit_check()
{
    COUNTER_FILE="$PROJECT_DIR/$EMAIL_COUNTER_FILE"

    CURRENT_TIME=$(date +%s)
    HOUR_AGO=$((CURRENT_TIME - 3600))


    mkdir -p "$(dirname "$COUNTER_FILE")"


    if [ ! -f "$COUNTER_FILE" ]; then
        touch "$COUNTER_FILE"
    fi


    # Remove entries older than 1 hour
    awk -v limit="$HOUR_AGO" -F'|' '$1 >= limit' "$COUNTER_FILE" \
        > "${COUNTER_FILE}.tmp"

    mv "${COUNTER_FILE}.tmp" "$COUNTER_FILE"


    COUNT=$(wc -l < "$COUNTER_FILE")


    if [ "$COUNT" -ge "$MAX_EMAILS_PER_HOUR" ]; then
        return 1
    fi


    echo "$CURRENT_TIME|email" >> "$COUNTER_FILE"

    return 0
}