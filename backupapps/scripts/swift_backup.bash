#!/bin/bash
#
# Backup script designed for cron
#
# Arguments:
#	$1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
	echo "Usage: bash swift_backup.bash (profile)"
	exit 1
fi
. $1

. "$SCRIPT_HOME/utility.bash"
if ! config_test; then
	exit 1
fi

database_backup_production


_do_upload() {
	_info "Backup to $3"
	duplicity full \
		--gpg-options "${GPG_OPTS}" \
		--verbosity notice \
		--encrypt-key "$1" \
		--num-retries 3 \
		--asynchronous-upload \
		--volsize 10 \
		--force \
		"$2" "$3"
}

_do_cleanup() {
	_info "Cleaning older than "$1$2" for $3"
	duplicity remove-older-than "$1$2" \
        --gpg-options "${GPG_OPTS}" \
		--verbosity notice \
		--force \
		"$3"
}

DEST_DAILY="$DEST_PREFIX-daily"
DEST_WEEKLY="$DEST_PREFIX-weekly"
DEST_MONTHLY="$DEST_PREFIX-monthly"


export PASSPHRASE=$ENCRYPT_PASSWORD

# === Uploads ===
_do_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_DAILY"

DAY_OF_WEEK=`date +%u`
if [ $DAY_OF_WEEK -eq $POLICY_DAY_FOR_WEEKLY ]; then
	_do_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_WEEKLY"
fi

DAY_OF_MONTH=`date +%d`
if [ $DAY_OF_MONTH -eq $POLICY_DAY_FOR_MONTHY ]; then
	_do_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_MONTHLY"
fi

# === Clean ups ===
_do_cleanup "$POLICY_DAYS_TO_KEEP" "D" "$DEST_DAILY"
_do_cleanup "$POLICY_WEEKS_TO_KEEP" "W" "$DEST_WEEKLY"
_do_cleanup "$POLICY_MONTHS_TO_KEEP" "M" "$DEST_MONTHLY"

unset PASSPHRASE

# Clean up to avoid leaving environment variables in shell
config_clear
