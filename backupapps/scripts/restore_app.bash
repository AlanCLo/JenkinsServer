#!/bin/bash
#
# Simple restore that is the counter part of a backup.
# Only intended as a manual operation.
# 
# Run this in parts by sourcing files as needed if you want to do something custom on the cli
#
# Arguments:
#    $1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
    echo "Usage: bash restore_app.bash (profile)"
    exit 1
fi
source "$1"

# Safe import of utility module 
SCRIPT_HOME=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
source "$SCRIPT_HOME/utility.bash"

# Check for required parameters in environment
if ! config_test; then
    exit 1
fi

# Fetch the last backup from daily
last_backup="$DEST_PREFIX-daily"
dup_restore "$last_backup" "$RESTORE_LOCATION"
_exitIfError "Failed to restore last backup at $last_backup"

# Clean up to avoid leaving environment variables in shell
config_clear

# We're done!
_info "SUCCESSFULLY COMPLETED"


