#!/usr/bin/env bash

#===============================================================================
# Services Library
#
# Inotify Security Monitor
# Installer v2.3
#===============================================================================


install_systemd_units()
{
    log_step "Installing systemd units"

    local FILE

    for FILE in "$SYSTEMD_SOURCE_DIR"/*.service "$SYSTEMD_SOURCE_DIR"/*.timer
    do
        [ -f "$FILE" ] || continue

        install -m 644 \
            "$FILE" \
            "$SYSTEMD_TARGET_DIR/"

        log_ok "$(basename "$FILE") installed"
    done

    return 0
}


reload_systemd()
{
    log_step "Reloading systemd"

    systemctl daemon-reload

    log_ok "systemd reload completed"

    return 0
}


enable_services()
{
    log_step "Enabling services"

    local SERVICES=(
        "inotify-security-monitor.service"
        "inotify-summary.timer"
        "inotify-logrotate.timer"
    )

    local SERVICE

    for SERVICE in "${SERVICES[@]}"
    do
        if systemctl enable "$SERVICE"; then
            log_ok "$SERVICE enabled"
        else
            log_error "Failed enabling $SERVICE"
            return 1
        fi
    done

    return 0
}


start_services()
{
    log_step "Starting services"

    local SERVICES=(
        "inotify-security-monitor.service"
        "inotify-summary.timer"
        "inotify-logrotate.timer"
    )

    local SERVICE

    for SERVICE in "${SERVICES[@]}"
    do
        if systemctl restart "$SERVICE"; then
            log_ok "$SERVICE started"
        else
            log_error "Failed starting $SERVICE"
            return 1
        fi
    done

    return 0
}


verify_services()
{
    log_step "Verifying services"

    local FAILED=0

    if systemctl is-active --quiet inotify-security-monitor.service; then
        log_ok "Monitor service running"
    else
        log_error "Monitor service is not running"
        FAILED=1
    fi


    if systemctl is-active --quiet inotify-summary.timer; then
        log_ok "Summary timer active"
    else
        log_warn "Summary timer not active"
    fi


    if systemctl is-active --quiet inotify-logrotate.timer; then
        log_ok "Logrotate timer active"
    else
        log_warn "Logrotate timer not active"
    fi


    return "$FAILED"
}