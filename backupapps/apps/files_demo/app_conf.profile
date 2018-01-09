#/bin/bash
# app_conf.profile
#
# A demo profile for a example application where we just want to backup a folder of files

export BACKUP_TARGET="/backupapps/apps/files_demo/conf_dir"
export DEST_PREFIX="file:///backupapps/filesystem/files_demo/files_demo"
export RESTORE_LOCATION="/backupapps/restore/files_demo/conf_dir"

export ENCRYPT_SIG=53EC22E53738F12F
export ENCRYPT_PASSWORD="demo"

export POLICY_DAYS_TO_KEEP=7
export POLICY_WEEKS_TO_KEEP=4
export POLICY_MONTHS_TO_KEEP=12
export POLICY_DAY_FOR_WEEKLY=7 # Sunday
export POLICY_DAY_FOR_MONTHY=1 # 1st day of month
