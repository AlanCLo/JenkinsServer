#!/bin/bash
#
# Creates and Updates a Test database by restoring a copy from daily backup
#
# Arguments:
#	$1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
	echo "Usage: bash update_test_db_from_backup.bash (profile)"
	exit 1
fi
. $1

. "$SCRIPT_HOME/utility.bash"
if ! config_test; then
	exit 1
fi

DEST_DAILY="$DEST_PREFIX-daily"

export PASSPHRASE=$ENCRYPT_PASSWORD

duplicity restore --verbosity notice \
    --gpg-options "${GPG_OPTS}" \
	--force \
	"$DEST_DAILY" "$RESTORE_DEFAULT_LOCATION"


database_restore_to_test "$RESTORE_DEFAULT_LOCATION"

unset PASSPHRASE

# Clean up to avoid leaving environment variables in shell
config_clear




