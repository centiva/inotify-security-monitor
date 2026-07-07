#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================="
echo " Inotify Security Monitor Installer"
echo "========================================="

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root."
    exit 1
fi

echo "[+] Installing dependencies..."

apt update
apt install -y \
    inotify-tools \
    mailutils \
    gzip

echo "[+] Creating directories..."

mkdir -p /etc/inotify-security-monitor
mkdir -p /var/log/inotify-security-monitor

echo "[+] Installing configuration..."

if [ ! -f /etc/inotify-security-monitor/inotify-security-monitor.conf ]; then
    cp "$PROJECT_DIR/config/inotify-security-monitor.conf" \
       /etc/inotify-security-monitor/
fi

echo "[+] Installing systemd units..."

cp "$PROJECT_DIR/systemd/"*.service /etc/systemd/system/
cp "$PROJECT_DIR/systemd/"*.timer /etc/systemd/system/

systemctl daemon-reload

echo
echo "Installation completed."
echo
echo "Enable services with:"
echo "  systemctl enable --now inotify-security-monitor.service"
echo "  systemctl enable --now inotify-summary.timer"
echo "  systemctl enable --now inotify-logrotate.timer"