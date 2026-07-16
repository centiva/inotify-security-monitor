#!/usr/bin/env bash

#===============================================================================
# Doctor
#
# Inotify Security Monitor
#===============================================================================

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