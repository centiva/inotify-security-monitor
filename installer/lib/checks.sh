#!/usr/bin/env bash

#===============================================================================
# Installer Checks Library
#
# Inotify Security Monitor
# Installer v2.3
#===============================================================================


check_root()
{
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Installer must be run as root."
        return 1
    fi

    log_ok "Running as root"
}


check_os()
{
    if [ "$(uname -s)" != "Linux" ]; then
        log_error "Unsupported operating system."
        return 1
    fi

    log_ok "Linux detected"
}


check_systemd()
{
    if ! command -v systemctl >/dev/null 2>&1; then
        log_error "systemd is not available."
        return 1
    fi

    log_ok "systemd detected"
}


check_command()
{
    local CMD="$1"

    if command -v "$CMD" >/dev/null 2>&1; then
        log_ok "$CMD found"
        return 0
    fi

    log_error "$CMD not found"
    return 1
}


check_dependencies()
{
    log_step "Checking dependencies"

    local FAILED=0

    for CMD in \
        bash \
        sha256sum \
        inotifywait
    do
        check_command "$CMD" || FAILED=1
    done


    if command -v mail >/dev/null 2>&1; then
        log_ok "mail found"
    else
        log_warn "mail command not found (email notifications may not work)"
    fi


    return "$FAILED"
}


check_project_structure()
{
    log_step "Checking project structure"

    local REQUIRED=(
        "scripts"
        "config"
        "systemd"
        "VERSION"
    )


    local ITEM

    for ITEM in "${REQUIRED[@]}"; do

        if [ ! -e "$PROJECT_ROOT/$ITEM" ]; then
            log_error "Missing: $ITEM"
            return 1
        fi

    done


    log_ok "Project structure valid"
}


run_environment_checks()
{
    check_root || return 1
    check_os || return 1
    check_systemd || return 1
    check_dependencies || return 1
    check_project_structure || return 1

    return 0
}
