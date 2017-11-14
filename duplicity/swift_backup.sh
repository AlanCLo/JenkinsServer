#!/bin/bash
#
# Backup script designed for cron
#
# Arguments:
#	$1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
	echo "Usage: swift_backup.sh (profile)"
	exit 1
fi
. $1

# Check for database parameters first
. "$SCRIPT_HOME/utility.sh"
if ! config_test; then
	exit 1
fi

database_backup_production


_do_upload() {
	duplicity full \
		--verbosity notice \
		--encrypt-key "$1" \
		--num-retries 3 \
		--asynchronous-upload \
		--volsize 10 \
		--force \
		"$2" "$3"
}

DEST_DAILY="$DEST_PREFIX-daily"
DEST_WEEKLY="$DEST_PREFIX-weekly"
DEST_MONTHLY="$DEST_PREFIX-monthly"


PASSPHRASE=$ENCRYPT_PASSWORD

_do_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_DAILY"

unset PASSPHRASE

# Clean up to avoid leaving environment variables in shell
config_clear
