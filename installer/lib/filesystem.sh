#!/usr/bin/env bash

#===============================================================================
# Filesystem Library
#
# Inotify Security Monitor
# Installer v2.3
#===============================================================================

create_directory()
{
    local DIR="$1"

    if [ -d "$DIR" ]; then
        log_ok "Directory exists: $DIR"
        return 0
    fi

    if mkdir -p "$DIR"; then
        log_ok "Created directory: $DIR"
        return 0
    fi

    log_error "Unable to create directory: $DIR"
    return 1
}


check_directory_writable()
{
    local DIR="$1"

    if [ ! -w "$DIR" ]; then
        log_error "Directory is not writable: $DIR"
        return 1
    fi

    log_ok "Directory writable: $DIR"
}


resolve_path()
{
    local PATHNAME="$1"

    case "$PATHNAME" in
        /*)
            printf "%s\n" "$PATHNAME"
            ;;
        *)
            printf "%s/%s\n" "$INSTALL_DIR" "${PATHNAME#./}"
            ;;
    esac
}


ensure_runtime_directories()
{
    log_step "Preparing filesystem"

    local LOG_DIR
    local QUEUE_DIR
    local ARCHIVE_PATH

    LOG_DIR="$(resolve_path "$(dirname "$LOG_FILE")")"
    QUEUE_DIR="$(resolve_path "$(dirname "$QUEUE_FILE")")"
    ARCHIVE_PATH="$(resolve_path "$ARCHIVE_DIR")"

    create_directory "$LOG_DIR" || return 1
    create_directory "$QUEUE_DIR" || return 1
    create_directory "$ARCHIVE_PATH" || return 1

    check_directory_writable "$LOG_DIR" || return 1
    check_directory_writable "$ARCHIVE_PATH" || return 1

    return 0
}


prepare_filesystem()
{
    ensure_runtime_directories
}
