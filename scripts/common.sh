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


array_contains() {

    local VALUE="$1"
    shift

    local ITEM

    for ITEM in "$@"; do

        if [ "$ITEM" = "$VALUE" ]; then
            return 0
        fi

    done

    return 1
}

build_filter_lists() {

    #
    # Directories
    #

    ALL_EXCLUDE_DIRS=("${DEFAULT_EXCLUDE_DIRS[@]}")

    for ITEM in "${EXCLUDE_DIRS[@]}"; do

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_DIRS[@]}"; then
            ALL_EXCLUDE_DIRS+=("$ITEM")
        fi

    done

    #
    # Files
    #

    ALL_EXCLUDE_FILES=("${DEFAULT_EXCLUDE_FILES[@]}")

    for ITEM in "${EXCLUDE_FILES[@]}"; do

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_FILES[@]}"; then
            ALL_EXCLUDE_FILES+=("$ITEM")
        fi

    done

    #
    # Extensions
    #

    ALL_EXCLUDE_EXTENSIONS=("${DEFAULT_EXCLUDE_EXTENSIONS[@]}")

    for ITEM in "${EXCLUDE_EXTENSIONS[@]}"; do

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_EXTENSIONS[@]}"; then
            ALL_EXCLUDE_EXTENSIONS+=("$ITEM")
        fi

    done
}

validate_configuration() {

    if [ "${#WATCH_DIRS[@]}" -eq 0 ]; then
        echo "ERROR: WATCH_DIRS is empty."
        exit 1
    fi

    if [ "${#WATCH_EXTENSIONS[@]}" -eq 0 ]; then
        echo "ERROR: MONITORED_EXTENSIONS is empty."
        exit 1
    fi

    if [ -z "$LOG_FILE" ]; then
        echo "ERROR: LOG_FILE is not configured."
        exit 1
    fi

    if [ -z "$QUEUE_FILE" ]; then
        echo "ERROR: QUEUE_FILE is not configured."
        exit 1
    fi

}

# shellcheck source=/dev/null
source "$CONFIG_FILE"
build_filter_lists
validate_configuration

# ==========================================
# Built-in filtering rules
# ==========================================

DEFAULT_EXCLUDE_DIRS=(
    ".git"
    ".svn"
    ".hg"

    "vendor"
    "node_modules"

    "__pycache__"
)

DEFAULT_EXCLUDE_FILES=(
    ".DS_Store"
    "Thumbs.db"
)

DEFAULT_EXCLUDE_EXTENSIONS=(
    jpg
    jpeg
    png
    gif
    webp
    bmp
    svg
    ico

    mp3
    mp4
    mov
    avi
)



# ==========================================
# Built-in filtering rules
# ==========================================

DEFAULT_EXCLUDE_DIRS=(
    ".git"
    ".svn"
    ".hg"

    "vendor"
    "node_modules"

    "cache"
    "tmp"

    ".well-known"

    "__pycache__"
)

DEFAULT_EXCLUDE_EXTENSIONS=(
    jpg
    jpeg
    png
    gif
    webp
    bmp
    svg
    ico

    css
    js
    map

    pdf
    zip
    gz
    tar

    mp3
    mp4
    avi
    mov

    log
)




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

log_filter() {
    local FILE="$1"
    log_info "Ignored: $FILE | Reason: $FILTER_REASON"
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
    local EXT

    EXT="${FILE##*.}"
    EXT="${EXT,,}"

    local ITEM

    for ITEM in "${MONITORED_EXTENSIONS[@]}"; do

        if [ "${ITEM,,}" = "$EXT" ]; then
            return 0
        fi

    done

    return 1

}

is_excluded_extension() {

    local FILE="$1"
    local EXT

    EXT="${FILE##*.}"
    EXT="${EXT,,}"

    local ITEM

    for ITEM in "${ALL_EXCLUDE_EXTENSIONS[@]}"; do

        if [ "$EXT" = "$ITEM" ]; then
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

    local ITEM

    for ITEM in "${ALL_EXCLUDE_FILES[@]}"; do

        if [ "$NAME" = "$ITEM" ]; then
            FILTER_REASON="excluded_file"
            return 0
        fi

    done

    return 1

}

is_excluded_directory() {

    local FILE="$1"

    IFS='/' read -ra PARTS <<< "$FILE"

    local PART
    local DIR

    for PART in "${PARTS[@]}"; do

        for DIR in "${ALL_EXCLUDE_DIRS[@]}"; do

            if [ "$PART" = "$DIR" ]; then
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
