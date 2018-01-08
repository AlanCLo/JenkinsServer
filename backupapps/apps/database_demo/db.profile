#/bin/bash
# db.profile
#
# A demo profile for a example application that has a PostgreSQL database.
# Assumes demo_setup.sh has been executed to setup the databases and imported demo keys for encryption

export BACKUP_POSTGRESQL="1"
export PRODUCTION_HOST=postgres
export PRODUCTION_PORT=5432
export PRODUCTION_USER=postgres
export PRODUCTION_PASSWORD="admin123"
export PRODUCTION_DB=demo_prod

export BACKUP_TARGET="/backupapps/data/database_demo/demo_database.sqlc"
export DEST_PREFIX="file:///backupapps/filesystem/database_demo/database_demo"
export RESTORE_LOCATION="/backupapps/restore/database_demo/demo_database.sqlc"

export ENCRYPT_SIG=53EC22E53738F12F
export ENCRYPT_PASSWORD="demo"

export POLICY_DAYS_TO_KEEP=7
export POLICY_WEEKS_TO_KEEP=4
export POLICY_MONTHS_TO_KEEP=12
export POLICY_DAY_FOR_WEEKLY=7 # Sunday
export POLICY_DAY_FOR_MONTHY=1 # 1st day of month
