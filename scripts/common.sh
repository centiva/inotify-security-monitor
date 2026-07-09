#!/usr/bin/env bash
#
#===============================================================================
# Inotify Security Monitor
#
# Shared Library
#
# Version: 2.2.0
#
# Description:
#   Common functions used by:
#     - inotify-monitor.sh
#     - ismctl
#     - send-email.sh
#     - rotate-logs.sh
#     - summary-engine.sh
#
# Compatibility:
#   v2.1 configuration format preserved.
#
#===============================================================================

set -u
set -o pipefail


#===============================================================================
# Configuration
#===============================================================================

CONFIG_FILE="${CONFIG_FILE:-/opt/inotify-security-monitor/config/inotify-security-monitor.conf}"


#===============================================================================
# Runtime globals
#===============================================================================

FILTER_REASON=""

ALL_EXCLUDE_DIRS=()
ALL_EXCLUDE_FILES=()
ALL_EXCLUDE_EXTENSIONS=()

ALL_EXCLUDE_DIR_PATTERNS=()
ALL_EXCLUDE_FILE_PATTERNS=()
#ALL_EXCLUDE_PATH_PATTERNS=()


#===============================================================================
# Logging
#===============================================================================

_timestamp()
{
    date '+%Y-%m-%d %H:%M:%S'
}


_log()
{
    local LEVEL="$1"
    local MESSAGE="$2"

    local LINE

    LINE="$(_timestamp) [$LEVEL] $MESSAGE"

    if [ -n "${LOG_FILE:-}" ]; then
        printf '%s\n' "$LINE" >> "$LOG_FILE"
    fi

    printf '%s\n' "$LINE"
}


log_info()
{
    _log "INFO" "$*"
}


log_warning()
{
    _log "WARNING" "$*"
}


log_error()
{
    _log "ERROR" "$*"
}


log_debug()
{
    if [ "${DEBUG:-no}" = "yes" ]; then
        _log "DEBUG" "$*"
    fi
}


log_filter()
{
    local FILE="$1"

    _log "FILTER" "$FILE ${FILTER_REASON:-unknown}"
}


#===============================================================================
# Dependency checking
#===============================================================================

check_dependency()
{
    local COMMAND="$1"

    if ! command -v "$COMMAND" >/dev/null 2>&1; then
        log_error "Missing dependency: $COMMAND"
        return 1
    fi

    return 0
}


#===============================================================================
# Hash calculation
#===============================================================================

calculate_hash()
{
    local FILE="$1"

    if [ ! -f "$FILE" ]; then
        return 1
    fi

    sha256sum "$FILE" 2>/dev/null | awk '{print $1}'
}


#===============================================================================
# Email helpers
#===============================================================================

email_rate_limit_check()
{
    return 0
}


send_email()
{
    local SUBJECT="$1"
    local MESSAGE="$2"


    if ! command -v mail >/dev/null 2>&1; then
        log_error "mail command not found"
        return 1
    fi


    if [ -z "${EMAIL_TO:-}" ]; then
        log_error "EMAIL_TO not configured"
        return 1
    fi


    printf '%s\n' "$MESSAGE" | mail \
        -s "$SUBJECT" \
        "$EMAIL_TO"
}


#===============================================================================
# Built-in filtering rules
#===============================================================================

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

    css

)


DEFAULT_EXCLUDE_DIR_PATTERNS=()

DEFAULT_EXCLUDE_FILE_PATTERNS=()

#DEFAULT_EXCLUDE_PATH_PATTERNS=()


#===============================================================================
# Helper functions
#===============================================================================

array_contains()
{
    local SEARCH="$1"

    shift


    local ITEM

    for ITEM in "$@"; do

        if [[ "$ITEM" == "$SEARCH" ]]; then
            return 0
        fi

    done


    return 1
}

#===============================================================================
# Build effective filter lists
#===============================================================================

build_filter_lists()
{

    #
    # Directories
    #

    ALL_EXCLUDE_DIRS=("${DEFAULT_EXCLUDE_DIRS[@]}")

    for ITEM in "${EXCLUDE_DIRS[@]}"; do

        [ -z "$ITEM" ] && continue

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_DIRS[@]}"; then
            ALL_EXCLUDE_DIRS+=("$ITEM")
        fi

    done

    #
    # Directory patterns
    #

    ALL_EXCLUDE_DIR_PATTERNS=("${DEFAULT_EXCLUDE_DIR_PATTERNS[@]}")

    for ITEM in "${EXCLUDE_DIRS[@]}"; do

        [ -z "$ITEM" ] && continue

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_DIRS[@]}"; then
            ALL_EXCLUDE_DIRS+=("$ITEM")
        fi

    done


    #
    # Files
    #

    ALL_EXCLUDE_FILES=("${DEFAULT_EXCLUDE_FILES[@]}")

    for ITEM in "${EXCLUDE_FILES[@]:-}"; do

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_FILES[@]}"; then
            ALL_EXCLUDE_FILES+=("$ITEM")
        fi

    done


    #
    # File patterns
    #

    ALL_EXCLUDE_FILE_PATTERNS=("${DEFAULT_EXCLUDE_FILE_PATTERNS[@]}")

    for ITEM in "${EXCLUDE_FILE_PATTERNS[@]:-}"; do

        if [ -n "$ITEM" ]; then
            ALL_EXCLUDE_FILE_PATTERNS+=("$ITEM")
        fi

    done


    #
    # Extensions
    #

    ALL_EXCLUDE_EXTENSIONS=("${DEFAULT_EXCLUDE_EXTENSIONS[@]}")

    for ITEM in "${EXCLUDE_DIRS[@]}"; do

        [ -z "$ITEM" ] && continue

        if ! array_contains "$ITEM" "${ALL_EXCLUDE_DIRS[@]}"; then
            ALL_EXCLUDE_DIRS+=("$ITEM")
        fi

    done

}


#===============================================================================
# Configuration validation
#===============================================================================

validate_configuration()
{

    local ERRORS=0


    #
    # Required arrays
    #

    if [ "${#WATCH_DIRS[@]}" -eq 0 ]; then
        log_error "WATCH_DIRS is empty."
        ERRORS=$((ERRORS + 1))
    fi


    if [ "${#WATCH_EXTENSIONS[@]}" -eq 0 ]; then
        log_error "WATCH_EXTENSIONS is empty."
        ERRORS=$((ERRORS + 1))
    fi


    #
    # Watch directories
    #

    for DIR in "${WATCH_DIRS[@]:-}"; do

        if [ ! -d "$DIR" ]; then
            log_error "Watch directory does not exist: $DIR"
            ERRORS=$((ERRORS + 1))
        fi

    done


    #
    # Log configuration
    #

    if [ -z "${LOG_FILE:-}" ]; then
        log_error "LOG_FILE is not configured."
        ERRORS=$((ERRORS + 1))
    fi


    if [ -z "${QUEUE_FILE:-}" ]; then
        log_error "QUEUE_FILE is not configured."
        ERRORS=$((ERRORS + 1))
    fi


    #
    # Email validation
    #

    if [ "${EMAIL_ENABLED:-false}" = "true" ]; then

        if [ -z "${EMAIL_TO:-}" ]; then
            log_error "EMAIL_TO is empty while email is enabled."
            ERRORS=$((ERRORS + 1))
        fi


        if [ -z "${SMTP_SERVER:-}" ]; then
            log_error "SMTP_SERVER is empty while email is enabled."
            ERRORS=$((ERRORS + 1))
        fi

    fi


    if [ "$ERRORS" -gt 0 ]; then

        log_error "Configuration validation failed: $ERRORS error(s)"
        return 1

    fi


    log_info "Configuration validation passed."

    return 0
}


#===============================================================================
# Configuration loading
#===============================================================================

load_configuration()
{

    if [ ! -f "$CONFIG_FILE" ]; then

        log_error "Configuration file not found: $CONFIG_FILE"
        return 1

    fi


    # shellcheck source=/dev/null
    source "$CONFIG_FILE"


    return 0
}


#===============================================================================
# Pattern matching
#===============================================================================

matches_pattern() {

    local FILE="$1"
    local PATTERN="$2"

    [[ "$FILE" == *$PATTERN* ]]

}


#===============================================================================
# Extension filtering
#===============================================================================

is_excluded_extension()
{

    local FILE="$1"

    local ITEM


    for ITEM in "${ALL_EXCLUDE_EXTENSIONS[@]}"; do

        if [[ "$FILE" == *."$ITEM" ]]; then

            FILTER_REASON="excluded_extension"
            return 0

        fi

    done


    return 1
}


#===============================================================================
# File filtering
#===============================================================================

is_excluded_file()
{

    local FILE="$1"

    local BASENAME
    BASENAME=$(basename "$FILE")


    local ITEM
    for ITEM in "${ALL_EXCLUDE_FILES[@]}"; do

        if [[ "$BASENAME" == "$ITEM" ]]; then

            FILTER_REASON="excluded_file"
            return 0

        fi

    done


    local PATTERN

    for PATTERN in "${ALL_EXCLUDE_FILE_PATTERNS[@]}"; do

        if matches_pattern "$FILE" "$PATTERN"; then

            FILTER_REASON="excluded_file_pattern"
            return 0

        fi

    done


    return 1
}


#===============================================================================
# Directory filtering
#===============================================================================

is_excluded_directory()
{

    local FILE="$1"

    local DIR

    for DIR in "${ALL_EXCLUDE_DIRS[@]}"; do

        if [[ "$FILE" == "$DIR"* ]]; then

            FILTER_REASON="excluded_directory"
            return 0

        fi

    done


    local PATTERN

    for PATTERN in "${ALL_EXCLUDE_DIR_PATTERNS[@]}"; do

        if matches_pattern "$FILE" "$PATTERN"; then

            FILTER_REASON="excluded_directory_pattern"
            return 0

        fi

    done


    return 1
}


#===============================================================================
# Main filtering decision
#===============================================================================

should_monitor_file()
{

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


    return 0
}

#===============================================================================
# Initialization
#===============================================================================

ism_init()
{

    load_configuration || return 1

    build_filter_lists

    validate_configuration || return 1

    return 0
}


#===============================================================================
# Automatic initialization
#
# Compatibility mode (v2.1 behavior)
#
# Existing scripts only need:
#
#     source common.sh
#
# No caller changes required.
#
#===============================================================================

ism_init