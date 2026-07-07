#!/usr/bin/env bash


# ==========================================
# Inotify Security Monitor
# Common Functions
# ==========================================


CONFIG_FILE="/etc/inotify-security-monitor.conf"


# Load configuration

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi



# ------------------------------------------
# Timestamp
# ------------------------------------------

timestamp()
{
    date "+%Y-%m-%d %H:%M:%S"
}



# ------------------------------------------
# Logging
# ------------------------------------------

log_info()
{
    echo "$(timestamp) [INFO] $*" | tee -a "$LOG_FILE"
}


log_warn()
{
    echo "$(timestamp) [WARN] $*" | tee -a "$LOG_FILE"
}


log_error()
{
    echo "$(timestamp) [ERROR] $*" | tee -a "$LOG_FILE" >&2
}



# ------------------------------------------
# Email
# ------------------------------------------

send_email()
{
    local SUBJECT="$1"
    local MESSAGE="$2"


    if [ "${ENABLE_EMAIL:-no}" != "yes" ]; then
        return 0
    fi


    echo "$MESSAGE" | mail -s "$SUBJECT" "$EMAIL"
}



# ------------------------------------------
# SHA256
# ------------------------------------------

calculate_hash()
{
    local FILE="$1"


    if [ -f "$FILE" ]; then
        sha256sum "$FILE" | awk '{print $1}'
    fi
}



# ------------------------------------------
# Dependency check
# ------------------------------------------

check_dependency()
{
    local CMD="$1"


    if ! command -v "$CMD" >/dev/null 2>&1
    then
        log_error "Missing dependency: $CMD"
        return 1
    fi


    return 0
}



# ------------------------------------------
# File extension check
# ------------------------------------------

is_monitored_extension()
{
    local FILE="$1"


    for EXT in "${WATCH_EXTENSIONS[@]}"
    do
        if [[ "$FILE" == *."$EXT" ]]
        then
            return 0
        fi
    done


    return 1
}