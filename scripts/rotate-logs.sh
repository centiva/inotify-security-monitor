#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_DIR/scripts/common.sh"

MAX_SIZE_BYTES=$((MAX_LOG_SIZE_MB * 1024 * 1024))

if [ ! -f "$LOG_FILE" ]; then
	exit 0
fi

CURRENT_SIZE=$(stat -c%s "$LOG_FILE")

if [ "$CURRENT_SIZE" -lt "$MAX_SIZE_BYTES" ]; then
	exit 0
fi

DATE=$(date +%Y%m%d-%H%M%S)

ARCHIVE="${LOG_FILE}.${DATE}"

mv "$LOG_FILE" "$ARCHIVE"

gzip "$ARCHIVE"

touch "$LOG_FILE"

log "Log rotated: ${ARCHIVE}.gz"

find "$(dirname "$LOG_FILE")" \
	-name "inotify-security-monitor.log.*.gz" \
	-mtime +"$LOG_RETENTION_DAYS" \
	-delete
