#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_DIR/scripts/common.sh"

REPORT_DIR="$PROJECT_DIR/reports"
REPORT_FILE="$REPORT_DIR/security-summary-$(date +%Y%m%d-%H%M%S).txt"

mkdir -p "$REPORT_DIR"

if [ ! -s "$QUEUE_FILE" ]; then
	log "Summary engine: no events found"
	exit 0
fi

log "Summary engine started"

TOTAL_EVENTS=$(wc -l <"$QUEUE_FILE")

{
	echo "====================================="
	echo "INOTIFY SECURITY SUMMARY REPORT"
	echo "====================================="
	echo
	echo "Generated:"
	date
	echo
	echo "Total events:"
	echo "$TOTAL_EVENTS"
	echo

	echo "Event Types"
	echo "-----------"

	awk -F'|' '{print $2}' "$QUEUE_FILE" | sort | uniq -c

	echo
	echo "Affected Files"
	echo "--------------"

	awk -F'|' '{print $3}' "$QUEUE_FILE"

	echo
	echo "SHA256"
	echo "------"

	awk -F'|' '{print $4}' "$QUEUE_FILE"

	echo
	echo "====================================="

} >"$REPORT_FILE"

: >"$QUEUE_FILE"

log "Summary created: $REPORT_FILE"
log "Processed $TOTAL_EVENTS events"
