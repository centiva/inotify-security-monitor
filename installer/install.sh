#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG_DIR="/etc/inotify-security-monitor"
CONFIG_FILE="$CONFIG_DIR/inotify-security-monitor.conf"

SYSTEMD_DIR="/etc/systemd/system"

SERVICE="inotify-security-monitor.service"
SUMMARY_TIMER="inotify-summary.timer"
ROTATE_TIMER="inotify-logrotate.timer"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[FAIL]${NC} $*"
    exit 1
}

require_root() {
    [[ $EUID -eq 0 ]] || error "Run this installer as root."
}

check_os() {
    command -v apt >/dev/null 2>&1 || \
        error "Only Debian/Ubuntu systems are currently supported."
}

install_packages() {

    local packages=(
        inotify-tools
        mailutils
        gzip
    )

    local missing=()

    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        success "All required packages are already installed."
        return
    fi

    info "Installing: ${missing[*]}"

    apt update
    apt install -y "${missing[@]}"
}

create_directories() {

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PROJECT_DIR/logs"
    mkdir -p "$PROJECT_DIR/reports"

    success "Directories created."
}

install_config() {

    if [ -f "$CONFIG_FILE" ]; then
        warn "Configuration already exists."
        warn "Keeping existing configuration."

        if [ ! -f "${CONFIG_FILE}.example" ]; then
            cp \
                "$PROJECT_DIR/config/inotify-security-monitor.conf" \
                "${CONFIG_FILE}.example"
        fi

        return
    fi

    cp \
        "$PROJECT_DIR/config/inotify-security-monitor.conf" \
        "$CONFIG_FILE"

    chmod 640 "$CONFIG_FILE"

    success "Configuration installed."
}

install_systemd() {

    cp "$PROJECT_DIR"/systemd/*.service "$SYSTEMD_DIR/"
    cp "$PROJECT_DIR"/systemd/*.timer "$SYSTEMD_DIR/"

    systemctl daemon-reload

    success "Systemd unit files installed."
}

enable_services() {

    systemctl enable "$SERVICE"
    systemctl enable "$SUMMARY_TIMER"
    systemctl enable "$ROTATE_TIMER"

    success "Services enabled."
}

start_services() {

    read -rp "Start services now? [Y/n] " answer

    answer="${answer:-Y}"

    if [[ "$answer" =~ ^[Yy]$ ]]; then

        systemctl restart "$SERVICE"
        systemctl restart "$SUMMARY_TIMER"
        systemctl restart "$ROTATE_TIMER"

        success "Services started."
    else
        warn "Services were not started."
    fi
}

show_summary() {

cat <<EOF

=========================================
 Inotify Security Monitor Installed
=========================================

Project:

  $PROJECT_DIR

Configuration:

  $CONFIG_FILE

Monitor:

  systemctl status $SERVICE

Summary Timer:

  systemctl status $SUMMARY_TIMER

Log Rotation:

  systemctl status $ROTATE_TIMER

EOF
}

main() {

    info "Installing Inotify Security Monitor"

    require_root

    check_os

    install_packages

    create_directories

    install_config

    install_systemd

    enable_services

    start_services

    show_summary
}

main
