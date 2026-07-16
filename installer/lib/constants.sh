#!/usr/bin/env bash

#===============================================================================
# Installer Constants
#
# Inotify Security Monitor
#===============================================================================

readonly PROJECT_NAME="Inotify Security Monitor"

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

readonly INSTALL_DIR="$PROJECT_ROOT"

readonly CONFIG_DIR="$PROJECT_ROOT/config"

readonly SCRIPT_DIR="$PROJECT_ROOT/scripts"

readonly SYSTEMD_SOURCE_DIR="$PROJECT_ROOT/systemd"

readonly SYSTEMD_TARGET_DIR="/etc/systemd/system"

readonly DATA_DIR="/var/lib/inotify-security-monitor"

readonly ARCHIVE_DIR_DEFAULT="$DATA_DIR/archive"

readonly LOG_DIR_DEFAULT="$PROJECT_ROOT/logs"

readonly REPORT_DIR_DEFAULT="$PROJECT_ROOT/reports"
