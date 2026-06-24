#!/bin/bash
# Apache debug log rotator - writes logs to date-based folders
# Usage: pipe Apache CustomLog output to this script

LOG_DIR="/var/log/apache2/reverse-proxy-debug"
DATE_FOLDER="$LOG_DIR/$(date +%Y-%m-%d)"

# Create date folder if it doesn't exist
mkdir -p "$DATE_FOLDER"

# Write to date-based log file
cat >> "$DATE_FOLDER/access.log"
