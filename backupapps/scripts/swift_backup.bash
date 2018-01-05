#!/bin/bash
#
# Backup script designed for cron
#
# Arguments:
#    $1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
    echo "Usage: bash swift_backup.bash (profile)"
    exit 1
fi
source $1

SCRIPT_HOME=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
source "$SCRIPT_HOME/utility.bash"
if ! config_test; then
    exit 1
fi

database_backup_production


DEST_DAILY="$DEST_PREFIX-daily"
DEST_WEEKLY="$DEST_PREFIX-weekly"
DEST_MONTHLY="$DEST_PREFIX-monthly"


export PASSPHRASE=$ENCRYPT_PASSWORD

# === Uploads ===
dup_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_DAILY"

DAY_OF_WEEK=`date +%u`
if [ $DAY_OF_WEEK -eq $POLICY_DAY_FOR_WEEKLY ]; then
    dup_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_WEEKLY"
fi

DAY_OF_MONTH=`date +%d`
if [ $DAY_OF_MONTH -eq $POLICY_DAY_FOR_MONTHY ]; then
    dup_upload "$ENCRYPT_SIG" "$BACKUP_FILE" "$DEST_MONTHLY"
fi

# === Clean ups ===
dup_cleanup "$POLICY_DAYS_TO_KEEP" "D" "$DEST_DAILY"
dup_cleanup "$POLICY_WEEKS_TO_KEEP" "W" "$DEST_WEEKLY"
dup_cleanup "$POLICY_MONTHS_TO_KEEP" "M" "$DEST_MONTHLY"

unset PASSPHRASE

# Clean up to avoid leaving environment variables in shell
config_clear
