#!/usr/bin/env bash

set -Eeuo pipefail

echo "Running smoke tests..."

bash -n scripts/common.sh
bash -n scripts/inotify-monitor.sh
bash -n scripts/summary-engine.sh
bash -n scripts/send-email.sh
bash -n scripts/rotate-logs.sh
bash -n installer/install.sh

echo "All syntax tests passed."
