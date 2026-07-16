#!/usr/bin/env bash

#===============================================================================
# Permissions Library
#
# Inotify Security Monitor
# Installer v2.3
#===============================================================================

prepare_permissions()
{
    log_step "Preparing permissions"

    # Make project shell scripts executable
    find "$PROJECT_ROOT/scripts" -type f -name "*.sh" -exec chmod 755 {} \;

    # Make installer scripts executable
    find "$PROJECT_ROOT/installer" -type f -name "*.sh" -exec chmod 755 {} \;

    log_ok "Script permissions updated"

    return 0
}