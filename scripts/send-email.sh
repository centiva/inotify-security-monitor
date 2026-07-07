#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_DIR/scripts/common.sh"

REPORT_FILE="$1"

if [ -z "$REPORT_FILE" ]; then
	echo "Usage: $0 <report-file>"
	exit 1
fi

if [ "$EMAIL_ENABLED" != "true" ]; then
	log "Email disabled"
	exit 0
fi

if [ ! -f "$REPORT_FILE" ]; then
	log "Report not found: $REPORT_FILE"
	exit 1
fi

if ! email_rate_limit_check; then

	log "Email rate limit exceeded. Notification suppressed."

	exit 0

fi

mail \
	-s "Inotify Security Report $(hostname)" \
	"$EMAIL_TO" <"$REPORT_FILE"

log "Email sent: $REPORT_FILE"
