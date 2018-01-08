#!/bin/bash
#
# Backup script designed for cron to backup application files and databases
#
# Arguments:
#    $1: Name of profile to source for parameters
#


if [ -z "$1" ]; then
    echo "Usage: bash backup_app.bash (profile)"
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

if [ "$BACKUP_POSTGRESQL" = "1" ]; then
    database_backup prod "$PRODUCTION_DB" "$BACKUP_TARGET"
    _exitIfError "Failed to backup production database"
fi

DEST_DAILY="$DEST_PREFIX-daily"
DEST_WEEKLY="$DEST_PREFIX-weekly"
DEST_MONTHLY="$DEST_PREFIX-monthly"


# === Uploads ===
dup_upload "$ENCRYPT_SIG" "$BACKUP_TARGET" "$DEST_DAILY"

DAY_OF_WEEK=`date +%u`
if [ $DAY_OF_WEEK -eq $POLICY_DAY_FOR_WEEKLY ]; then
    dup_upload "$ENCRYPT_SIG" "$BACKUP_TARGET" "$DEST_WEEKLY"
fi

DAY_OF_MONTH=`date +%d`
if [ $DAY_OF_MONTH -eq $POLICY_DAY_FOR_MONTHY ]; then
    dup_upload "$ENCRYPT_SIG" "$BACKUP_TARGET" "$DEST_MONTHLY"
fi

# === Clean ups ===
dup_cleanup "$POLICY_DAYS_TO_KEEP" "D" "$DEST_DAILY"
dup_cleanup "$POLICY_WEEKS_TO_KEEP" "W" "$DEST_WEEKLY"
dup_cleanup "$POLICY_MONTHS_TO_KEEP" "M" "$DEST_MONTHLY"


# Clean up to avoid leaving environment variables in shell
config_clear

# We're done!
_info "SUCCESSFULLY COMPLETED"



