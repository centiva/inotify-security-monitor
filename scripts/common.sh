#!/usr/bin/env bash

set -u

# ==========================================
# Configuration loading
# ==========================================

CONFIG_FILE="${CONFIG_FILE:-/opt/inotify-security-monitor/config/inotify-security-monitor.conf}"


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


DEFAULT_EXCLUDE_DIR_PATTERNS=()

DEFAULT_EXCLUDE_FILE_PATTERNS=()

DEFAULT_EXCLUDE_PATH_PATTERNS=()


# ==========================================
# Helper functions
# ==========================================

array_contains() {

    local SEARCH="$1"
    shift

    for ITEM in "$@"; do

        if [[ "$ITEM" == "$SEARCH" ]]; then
            return 0
        fi

    done

    return 1
}


# ==========================================
# Build effective filter lists
# ==========================================

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
    # Directory patterns
    #

    ALL_EXCLUDE_DIR_PATTERNS=("${DEFAULT_EXCLUDE_DIR_PATTERNS[@]}")

    for ITEM in "${EXCLUDE_DIR_PATTERNS[@]}"; do

        if [ -n "$ITEM" ]; then
            ALL_EXCLUDE_DIR_PATTERNS+=("$ITEM")
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
    # File patterns
    #

    ALL_EXCLUDE_FILE_PATTERNS=("${DEFAULT_EXCLUDE_FILE_PATTERNS[@]}")

    for ITEM in "${EXCLUDE_FILE_PATTERNS[@]}"; do

        if [ -n "$ITEM" ]; then
            ALL_EXCLUDE_FILE_PATTERNS+=("$ITEM")
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


# ==========================================
# Configuration validation
# ==========================================

validate_configuration() {

    local ERRORS=0


    #
    # Required arrays
    #

    if [ "${#WATCH_DIRS[@]}" -eq 0 ]; then
        echo "ERROR: WATCH_DIRS is empty."
        ERRORS=$((ERRORS+1))
    fi


    if [ "${#WATCH_EXTENSIONS[@]}" -eq 0 ]; then
        echo "ERROR: WATCH_EXTENSIONS is empty."
        ERRORS=$((ERRORS+1))
    fi


    #
    # Watch directories
    #

    for DIR in "${WATCH_DIRS[@]}"; do

        if [ ! -d "$DIR" ]; then
            echo "ERROR: Watch directory does not exist: $DIR"
            ERRORS=$((ERRORS+1))
        fi

    done


    #
    # Log configuration
    #

    if [ -z "${LOG_FILE:-}" ]; then
        echo "ERROR: LOG_FILE is not configured."
        ERRORS=$((ERRORS+1))
    fi


    if [ -z "${QUEUE_FILE:-}" ]; then
        echo "ERROR: QUEUE_FILE is not configured."
        ERRORS=$((ERRORS+1))
    fi


    #
    # Email validation
    #

    if [ "${EMAIL_ENABLED:-false}" = "true" ]; then

        if [ -z "${EMAIL_TO:-}" ]; then
            echo "ERROR: EMAIL_TO is empty while email is enabled."
            ERRORS=$((ERRORS+1))
        fi

        if [ -z "${SMTP_SERVER:-}" ]; then
            echo "ERROR: SMTP_SERVER is empty while email is enabled."
            ERRORS=$((ERRORS+1))
        fi

    fi


    if [ "$ERRORS" -gt 0 ]; then
        echo "Configuration validation failed: $ERRORS error(s)"
        return 1
    fi


    echo "Configuration validation passed."
    return 0
}

# ==========================================
# Load configuration
# ==========================================

# shellcheck source=/dev/null
# Build final lists AFTER defaults + config exist

source "$CONFIG_FILE"

build_filter_lists

validate_configuration || exit 1


# ==========================================
# Pattern matching
# ==========================================

matches_pattern() {

    local FILE="$1"
    local PATTERN="$2"

    [[ "$FILE" == $PATTERN ]]

}


# ==========================================
# Extension filtering
# ==========================================

is_excluded_extension() {

    local FILE="$1"

    for ITEM in "${ALL_EXCLUDE_EXTENSIONS[@]}"; do

        if [[ "$FILE" == *."$ITEM" ]]; then
            FILTER_REASON="excluded_extension"
            return 0
        fi

    done

    return 1
}


# ==========================================
# File filtering
# ==========================================

is_excluded_file() {

    local FILE="$1"

    local BASENAME
    BASENAME=$(basename "$FILE")


    for ITEM in "${ALL_EXCLUDE_FILES[@]}"; do

        if [[ "$BASENAME" == "$ITEM" ]]; then
            FILTER_REASON="excluded_file"
            return 0
        fi

    done


    for PATTERN in "${ALL_EXCLUDE_FILE_PATTERNS[@]}"; do

        if matches_pattern "$FILE" "$PATTERN"; then
            FILTER_REASON="excluded_file_pattern"
            return 0
        fi

    done


    return 1
}


# ==========================================
# Directory filtering
# ==========================================

is_excluded_directory() {

    local FILE="$1"


    for DIR in "${ALL_EXCLUDE_DIRS[@]}"; do

        if [[ "$FILE" == "$DIR"* ]]; then
            FILTER_REASON="excluded_directory"
            return 0
        fi

    done


    for PATTERN in "${ALL_EXCLUDE_DIR_PATTERNS[@]}"; do

        if matches_pattern "$FILE" "$PATTERN"; then
            FILTER_REASON="excluded_directory_pattern"
            return 0
        fi

    done


    return 1
}


# ==========================================
# Main filtering decision
# ==========================================

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


    return 0
}
