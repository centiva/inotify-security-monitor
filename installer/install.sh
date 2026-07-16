#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$PROJECT_ROOT"

source "$PROJECT_ROOT/config/inotify-security-monitor.conf"

source "$PROJECT_ROOT/installer/lib/constants.sh"
source "$PROJECT_ROOT/installer/lib/output.sh"
source "$PROJECT_ROOT/installer/lib/checks.sh"
source "$PROJECT_ROOT/installer/lib/filesystem.sh"
source "$PROJECT_ROOT/installer/lib/permissions.sh"
source "$PROJECT_ROOT/installer/lib/services.sh"
source "$PROJECT_ROOT/installer/doctor.sh"

print_banner

run_environment_checks

prepare_filesystem

prepare_permissions

install_systemd_units

reload_systemd

enable_services

start_services

run_doctor

log_ok "Installation completed successfully."

exit 0