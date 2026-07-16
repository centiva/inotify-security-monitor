#!/usr/bin/env bash

#===============================================================================
# Doctor
#
# Inotify Security Monitor
#===============================================================================


set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/config/inotify-security-monitor.conf"

source "$PROJECT_ROOT/installer/lib/constants.sh"
source "$PROJECT_ROOT/installer/lib/output.sh"
source "$PROJECT_ROOT/installer/lib/checks.sh"
source "$PROJECT_ROOT/installer/lib/services.sh"

run_doctor()
{
    log_step "Running health checks"

    local FAILED=0


    if systemctl is-active --quiet inotify-security-monitor.service; then
        log_ok "Monitor service running"
    else
        log_error "Monitor service not running"
        FAILED=1
    fi


    if systemctl is-enabled --quiet inotify-summary.timer; then
        log_ok "Summary timer enabled"
    else
        log_warn "Summary timer not enabled"
    fi


    if systemctl is-enabled --quiet inotify-logrotate.timer; then
        log_ok "Logrotate timer enabled"
    else
        log_warn "Logrotate timer not enabled"
    fi


    if [ -f "$LOG_FILE" ]; then
        log_ok "Log file available"
    else
        log_warn "Log file not found yet"
    fi


    return "$FAILED"
}

check_email_configuration()
{
    log_step "Checking email configuration"

    local FAILED=0

    if [ "${EMAIL_ENABLED:-false}" = "true" ]; then

        if [ -n "${EMAIL_TO:-}" ]; then
            log_ok "EMAIL_TO configured"
        else
            log_error "EMAIL_TO missing"
            FAILED=1
        fi


        if [ "${#EMAIL_EVENTS[@]}" -gt 0 ]; then
            log_ok "EMAIL_EVENTS configured"
        else
            log_error "EMAIL_EVENTS missing"
            FAILED=1
        fi


        if [ "${#EMAIL_EXTENSIONS[@]}" -gt 0 ]; then
            log_ok "EMAIL_EXTENSIONS configured"
        else
            log_error "EMAIL_EXTENSIONS missing"
            FAILED=1
        fi

    else
        log_warn "Email notifications disabled"
    fi

    return "$FAILED"
}

run_doctor
check_email_configuration