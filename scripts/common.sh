#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

SYSTEM_CONFIG="/etc/inotify-security-monitor/inotify-security-monitor.conf"
LOCAL_CONFIG="$PROJECT_DIR/config/inotify-security-monitor.conf"

if [ -f "$SYSTEM_CONFIG" ]; then
    CONFIG_FILE="$SYSTEM_CONFIG"
else
    CONFIG_FILE="$LOCAL_CONFIG"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found."
    echo "Checked:"
    echo "  $SYSTEM_CONFIG"
    echo "  $LOCAL_CONFIG"
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ==========================================
# Logging
# ==========================================

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

log_info() {
	log "[INFO] $1"
}

log_warning() {
	log "[WARNING] $1"
}

log_error() {
	log "[ERROR] $1"
}

# ==========================================
# Dependencies
# ==========================================

check_dependency() {
	COMMAND="$1"

	if ! command -v "$COMMAND" >/dev/null 2>&1; then
		log_error "Missing dependency: $COMMAND"
		exit 1
	fi
}

# ==========================================
# File filtering & helpers
# ==========================================

calculate_hash() {
	FILE="$1"

	if [ -f "$FILE" ]; then
		sha256sum "$FILE" | awk '{print $1}'
	else
		echo ""
	fi
}

is_monitored_extension() {

    local FILE="$1"
    local EXT="${FILE##*.}"

    EXT="${EXT,,}"

    for item in "${MONITORED_EXTENSIONS[@]}"; do
        if [ "$EXT" = "$item" ]; then
            return 0
        fi
    done

    return 1
}

is_excluded_extension() {

    local FILE="$1"
    local EXT="${FILE##*.}"

    EXT="${EXT,,}"

    for item in "${EXCLUDE_EXTENSIONS[@]}"; do
        if [ "$EXT" = "$item" ]; then
            FILTER_REASON="excluded_extension"
            return 0
        fi
    done

    return 1
}

is_excluded_file() {

    local FILE="$1"
    local NAME

    NAME="$(basename "$FILE")"

    for item in "${EXCLUDE_FILES[@]}"; do
        if [ "$NAME" = "$item" ]; then
            FILTER_REASON="excluded_file"
            return 0
        fi
    done

    return 1
}

is_excluded_directory() {

    local FILE="$1"

    IFS='/' read -ra PARTS <<< "$FILE"

    for part in "${PARTS[@]}"; do

        for item in "${EXCLUDE_DIRS[@]}"; do

            if [ "$part" = "$item" ]; then
                FILTER_REASON="excluded_directory"
                return 0
            fi

        done

    done

    return 1
}

should_monitor_file() {

    local FILE="$1"

    FILTER_REASON=""

    if is_excluded_directory "$FILE"; then
        return 1
    fi

    if is_excluded_file "$FILE"; then
        return 1
    fi

    if is_excluded_extension "$FILE"; then
        return 1
    fi

    if ! is_monitored_extension "$FILE"; then
        FILTER_REASON="not_monitored_extension"
        return 1
    fi

    return 0
}


# ==========================================
# Email
# ==========================================

send_email() {
	SUBJECT="$1"
	MESSAGE="$2"

	if [ "${ENABLE_EMAIL:-no}" != "yes" ]; then
		return 0
	fi

	echo "$MESSAGE" | mail \
		-s "$SUBJECT" \
		"$EMAIL_TO"

	log_info "Email sent: $SUBJECT"
}

# ==========================================
# Rate limiting
# ==========================================

email_rate_limit_check() {
	COUNTER_FILE="$PROJECT_DIR/$EMAIL_COUNTER_FILE"

	CURRENT_TIME=$(date +%s)
	HOUR_AGO=$((CURRENT_TIME - 3600))

	mkdir -p "$(dirname "$COUNTER_FILE")"

	touch "$COUNTER_FILE"

	awk -v limit="$HOUR_AGO" -F'|' \
		'$1 >= limit' \
		"$COUNTER_FILE" \
		>"${COUNTER_FILE}.tmp"

	mv "${COUNTER_FILE}.tmp" "$COUNTER_FILE"

	COUNT=$(wc -l <"$COUNTER_FILE")

	if [ "$COUNT" -ge "$MAX_EMAILS_PER_HOUR" ]; then
		return 1
	fi

	echo "$CURRENT_TIME|email" >>"$COUNTER_FILE"

	return 0
}
