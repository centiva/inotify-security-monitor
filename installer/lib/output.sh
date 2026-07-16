#!/usr/bin/env bash

#===============================================================================
# Output Library
#
# Inotify Security Monitor
# Installer v2.3
#===============================================================================

readonly COLOR_RED="\033[0;31m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_BLUE="\033[0;34m"
readonly COLOR_RESET="\033[0m"


print_banner()
{
    echo

    echo "============================================================"
    echo " Inotify Security Monitor Installer"
    echo " Version $(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "Unknown")"
    echo "============================================================"

    echo
}


log_step()
{
    printf "${COLOR_BLUE}[STEP]${COLOR_RESET} %s\n" "$1"
}


log_ok()
{
    printf "${COLOR_GREEN}[ OK ]${COLOR_RESET} %s\n" "$1"
}


log_warn()
{
    printf "${COLOR_YELLOW}[WARN]${COLOR_RESET} %s\n" "$1"
}


log_error()
{
    printf "${COLOR_RED}[FAIL]${COLOR_RESET} %s\n" "$1"
}


log_info()
{
    printf "[INFO] %s\n" "$1"
}


die()
{
    log_error "$1"
    exit 1
}
