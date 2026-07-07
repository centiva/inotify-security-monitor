# Inotify Security Monitor

A lightweight Linux filesystem security monitoring tool based on inotify.

The project monitors filesystem activity in real time and provides security notifications when suspicious files are created, modified, moved, or deleted.

## Features

- Real-time filesystem monitoring
- File creation detection
- File modification detection
- File movement detection
- Suspicious extension detection
- SHA256 file hashing
- Email notifications
- Event queue system
- Periodic summary reports
- Systemd service integration
- Log rotation
- Easy installation

## Security Purpose

The main goal is to detect suspicious activity on Linux servers, especially:

- PHP malware uploads
- Web shells
- Unauthorized file changes
- Compromised websites
- Suspicious scripts

## Supported Files

Default monitored extensions:

- PHP
- PHTML
- PHAR
- CGI
- Perl
- Python
- Shell scripts
- JavaScript

## Installation

Installation will be performed using:

```bash
sudo ./install.sh