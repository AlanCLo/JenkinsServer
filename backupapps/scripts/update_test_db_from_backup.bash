#!/bin/bash
#
# Creates and Updates a Test database by restoring a copy from daily backup
#
# Arguments:
#    $1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
    echo "Usage: bash update_test_db_from_backup.bash (profile)"
    exit 1
fi
. $1

SCRIPT_HOME=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
source "$SCRIPT_HOME/utility.bash"
if ! config_test; then
    exit 1
fi

last_backup="$DEST_PREFIX-daily"

export PASSPHRASE=$ENCRYPT_PASSWORD
dup_restore "$last_backup" "$RESTORE_LOCATION"

database_restore_to_test "$RESTORE_LOCATION"


# Clean up to avoid leaving environment variables in shell
unset PASSPHRASE
config_clear




