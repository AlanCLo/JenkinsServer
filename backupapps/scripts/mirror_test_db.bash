#!/bin/bash
#
# Creates and Updates a Test database by restoring a copy from daily backup
#
# Arguments:
#    $1: Name of mirror-profile to source for parameters
#


if [ -z "$1" ]; then
    echo "Usage: bash mirror_test_db.bash (profile)"
    exit 1
fi
source $1

export MIRROR_POSTGRESQL="1"

SCRIPT_HOME=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
source "$SCRIPT_HOME/utility.bash"
if ! config_test; then
    exit 1
fi

# Fetch the last backup from daily
last_backup="$DEST_PREFIX-daily"
dup_restore "$last_backup" "$RESTORE_LOCATION"
_exitIfError "Failed to restore last backup at $last_backup"

# Restore database
database_restore_to_test "$RESTORE_LOCATION"


# Clean up to avoid leaving environment variables in shell
config_clear

_info "SUCCESSFULLY COMPLETED"


