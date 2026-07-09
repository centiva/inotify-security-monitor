# Inotify Security Monitor v2.2

## Administrator Manual

Version: 2.2
Project: Inotify Security Monitor
Installation Path:

```text
/opt/inotify-security-monitor
```

---

# 1. Introduction

Inotify Security Monitor is a lightweight Linux security monitoring tool that watches important directories and detects suspicious file changes in real time.

It is designed mainly for web servers running:

* WordPress
* Joomla
* PHP applications
* Hosting environments
* Shared hosting servers

## Main Features

* Real-time monitoring using Linux inotify
* File creation detection
* File modification detection
* File movement detection
* Attribute change detection
* Extension filtering
* Directory exclusions
* File exclusions
* Wildcard pattern exclusions
* Hash calculation
* File archiving
* Email notifications
* Security reports
* Configuration validation
* Systemd integration

---

# 2. Requirements

Supported operating systems:

* Debian 11+
* Debian 12+
* Ubuntu 20.04+
* Ubuntu 22.04+
* Ubuntu 24.04+

Required packages:

```bash
apt update

apt install -y \
git \
inotify-tools \
mailutils
```

Verify inotify:

```bash
inotifywait --version
```

---

# 3. New VPS Installation

## 3.1 Clone Repository

Go to installation directory:

```bash
cd /opt
```

Clone:

```bash
git clone https://github.com/centiva/inotify-security-monitor.git
```

Enter directory:

```bash
cd /opt/inotify-security-monitor
```

---

# 4. Select Version

## Production Release

Example:

```bash
git checkout v2.2.0
```

## Development Branch

Example:

```bash
git checkout develop-v2.2
```

Check current version:

```bash
git log --oneline -1
```

Check available versions:

```bash
git tag -l
```

Example:

```text
v1.0.0
v2.0.0-frozen
v2.1.0
v2.2.0
```

---

# 5. Configuration

Main configuration file:

```text
config/inotify-security-monitor.conf
```

Edit:

```bash
nano config/inotify-security-monitor.conf
```

---

# 6. Configure Monitored Directories

Example:

```bash
WATCH_DIRS=(
    "/home/example/domains/site.gr/public_html"
)
```

Multiple websites:

```bash
WATCH_DIRS=(
    "/home/site1/public_html"
    "/home/site2/public_html"
    "/var/www/html"
)
```

After changing configuration:

```bash
systemctl restart inotify-security-monitor
```

---

# 7. Directory Exclusions

There are three exclusion methods.

---

## 7.1 Exact Directory Exclusion

Use:

```bash
EXCLUDE_DIRS=(
    "/home/site/public_html/cache"
    "/home/site/public_html/tmp"
)
```

Example ignored paths:

```text
/home/site/public_html/cache/file.php
/home/site/public_html/tmp/test.php
```

---

## 7.2 Default Directory Exclusions

The following directories are ignored automatically:

```text
.git
.svn
.hg
vendor
node_modules
__pycache__
```

Example:

```text
/home/site/public_html/vendor/package/file.php
```

will not generate an alert.

---

## 7.3 Wildcard Directory Patterns

Recommended method for hosting environments.

Configuration:

```bash
EXCLUDE_DIR_PATTERNS=(
    "*/bfnetwork/*"
    "*/cache/*"
    "*/tmp/*"
)
```

Examples ignored:

```text
/home/site/public_html/bfnetwork/file.php

/home/site/public_html/cache/index.php

/home/site/public_html/tmp/session.php
```

---

# 8. File Exclusions

## Exact Files

Example:

```bash
EXCLUDE_FILES=(
    ".DS_Store"
    "Thumbs.db"
)
```

Ignored:

```text
/home/site/public_html/.DS_Store
```

---

## File Patterns

Example:

```bash
EXCLUDE_FILE_PATTERNS=(
    "*.log"
    "*.bak"
)
```

Ignored:

```text
error.log
backup.bak
```

---

# 9. Extension Filtering

## Monitored Extensions

Only these extensions are analyzed:

Example:

```bash
WATCH_EXTENSIONS=(
    "php"
    "phtml"
    "phar"
    "cgi"
    "pl"
    "py"
    "sh"
    "js"
)
```

---

## Excluded Extensions

Example:

```bash
EXCLUDE_EXTENSIONS=(
    "jpg"
    "jpeg"
    "png"
    "gif"
)
```

Ignored:

```text
image.jpg
logo.png
banner.gif
```

---

# 10. Configuration Validation

Before starting the service, validate configuration:

```bash
./tests/filter-test.sh
```

Expected:

```text
Configuration validation passed.
```

Example:

```text
PROCESS: /tmp/test.php

IGNORE : /tmp/image.jpg (excluded_extension)

IGNORE : /tmp/cache/index.php (excluded_directory_pattern)
```

---

# 11. Install System Service

Run:

```bash
./install.sh
```

Enable:

```bash
systemctl enable inotify-security-monitor
```

Start:

```bash
systemctl start inotify-security-monitor
```

Check:

```bash
systemctl status inotify-security-monitor
```

Expected:

```text
Active: active (running)
```

---

# 12. Updating Existing VPS Installation

## 12.1 Check Current Version

```bash
cd /opt/inotify-security-monitor

git status

git log --oneline -1
```

---

## 12.2 Backup Configuration

Before update:

```bash
cp config/inotify-security-monitor.conf \
config/inotify-security-monitor.conf.backup
```

---

## 12.3 Update Code

Fetch:

```bash
git fetch origin
```

Update:

```bash
git pull origin develop-v2.2
```

or switch release:

```bash
git checkout v2.2.0
```

---

## 12.4 Validate

Run:

```bash
./tests/smoke-test.sh
```

Expected:

```text
All syntax tests passed.
```

---

## 12.5 Restart Service

```bash
systemctl restart inotify-security-monitor
```

Check:

```bash
systemctl status inotify-security-monitor
```

---

# 13. Logs

Main security log:

```text
logs/inotify-security-monitor.log
```

Event queue:

```text
logs/inotify-security-monitor.queue
```

Reports:

```text
reports/
```

View logs:

```bash
tail -f logs/inotify-security-monitor.log
```

---

# 14. Email Configuration

Example:

```bash
EMAIL_ENABLED=true

EMAIL_TO="admin@example.com"

SMTP_SERVER="localhost"

SMTP_PORT=25
```

Restart after changes:

```bash
systemctl restart inotify-security-monitor
```

---

# 15. Troubleshooting

## Service Failed

Check:

```bash
systemctl status inotify-security-monitor
```

Detailed logs:

```bash
journalctl -u inotify-security-monitor -n 100
```

---

## Configuration Error

Run:

```bash
./tests/filter-test.sh
```

Example:

```text
ERROR: Watch directory does not exist:
/home/example/public_html
```

Fix:

```bash
nano config/inotify-security-monitor.conf
```

---

## Check Running Watches

```bash
ps aux | grep inotify
```

Example:

```text
inotifywait -m -r
```

---

# 16. Recommended Production Workflow

For every VPS:

1. Backup configuration

```bash
cp config/inotify-security-monitor.conf backup.conf
```

2. Update repository

```bash
git pull origin develop-v2.2
```

3. Run tests

```bash
./tests/smoke-test.sh
```

4. Restart service

```bash
systemctl restart inotify-security-monitor
```

5. Verify status

```bash
systemctl status inotify-security-monitor
```

6. Monitor logs

```bash
tail -f logs/inotify-security-monitor.log
```

---

# 17. Support Information

Project directory:

```text
/opt/inotify-security-monitor
```

Configuration:

```text
config/inotify-security-monitor.conf
```

Scripts:

```text
scripts/
```

Systemd files:

```text
systemd/
```

Tests:

```text
tests/
```

---

End of Administrator Manual
