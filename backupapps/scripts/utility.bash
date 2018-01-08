#!/bin/bash
#
# Helper and Utility functions for database backup and restoration.
# Based on:
#    - PostgreSQL databases
#    - gnupg 1 or 2 encryption & signing
#    - Duplicity
#    - OpenStack SWIFT
#
# Assume configuration paramters are in the environment by souring a profile for a given project.
# Designed for you to source this file so that you can have include in scripts or to get all the functions to setup, test and debug with on commandline
#

# List of required environment variables for this utility
_backup_params=($(cat <<EOF
BACKUP_TARGET
DEST_PREFIX
RESTORE_LOCATION
ENCRYPT_SIG
ENCRYPT_PASSWORD
POLICY_DAYS_TO_KEEP
POLICY_WEEKS_TO_KEEP
POLICY_MONTHS_TO_KEEP
POLICY_DAY_FOR_WEEKLY
POLICY_DAY_FOR_MONTHY
EOF
))

# =====
# Extra options
# =====

# Params for backing up PostgreSQL database
if [ "$BACKUP_POSTGRESQL" = "1" ]; then
    _extra_params=($(cat <<EOF
PRODUCTION_HOST
PRODUCTION_PORT
PRODUCTION_USER
PRODUCTION_PASSWORD
PRODUCTION_DB
EOF
))
    _backup_params=("${_backup_params[@]}" "${_extra_params[@]}")
fi

# Params for mirroring PostgreSQL database to test instance
if [ "$MIRROR_POSTGRESQL" = "1" ]; then
    _extra_params=($(cat <<EOF
TEST_HOST
TEST_PORT
TEST_USER
TEST_PASSWORD
TEST_DB
EOF
))
    _backup_params=("${_backup_params[@]}" "${_extra_params[@]}")
fi

# Params if using a SWIFT backend for backup
if [ "${DEST_PREFIX:0:5}" = "swift" ]; then
    _extra_params=($(cat <<EOF
SWIFT_USERNAME
SWIFT_PASSWORD
SWIFT_AUTHURL
SWIFT_AUTHVERSION
EOF
))
    _backup_params=("${_backup_params[@]}" "${_extra_params[@]}")
fi


# =====
# Helper functions
# =====

#####
# Error stream print to stderr
# Arguments:
#    Stuff you want to print
# Return:
#    None
#####
_err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $@" >&2
}

#####
# Standard print with prefixes to stdout
# Arguments:
#    Stuff you want to print
# Return:
#    None
#####
_info() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] INFO: $@"
}

#####
# Shortcut to exit a script if the previous shell command has errored and with a message to error steam
# Arguments:
#    Stuff you want to print
# Return:
#    None
#####
_exitIfError() {
    if [ $? -ne 0 ]; then
        _err $1
        exit 1
    fi
}

#####
# Shortcut to switch between 2 profiles
# Arguments:
#    $1: either 'prod' or 'test'
# Return:
#    None
#####
_database_set_profile() {
    if [ "$1" == "prod" ]; then
        DB_HOST=$PRODUCTION_HOST
        DB_PORT=$PRODUCTION_PORT
        DB_USER=$PRODUCTION_USER
        export PGPASSWORD=$PRODUCTION_PASSWORD
        DB_NAME=$PRODUCTION_DB
    elif [ "$1" == "test" ]; then
        DB_HOST=$TEST_HOST
        DB_PORT=$TEST_PORT
        DB_USER=$TEST_USER
        export PGPASSWORD=$TEST_PASSWORD
        DB_NAME=$TEST_DB
    else
        echo "Usage: _database_set_profile (prod|test)"
        exit 1
    fi
}
#####
# Shortcut to clean up environment vars
# Arguments:
#    None
# Return:
#    None
#####
_database_unset() {
    unset PGPASSWORD
}

#####
# Checks the existence of a database 
# Arguments:
#    $1: either 'prod' or 'test'
#    $2: name of database
# Return:
#    Exit status of psql. i.e. 0 for success, non-zero for failure
#####
_database_exists() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: _database_exists (prod|test) (db name)"
        return
    fi
    _database_set_profile $1
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d '|' -f 1 | grep -qw $2
    RESULT=$?
    return $RESULT
}

#####
# Drops database (only in test profile!)
# Arguments:
#    $1: name of database
# Return:
#    Exit status of psql. i.e. 0 for success, non-zero for failure
#####
_database_drop() {
    if [ -z "$1" ]; then
        echo "Usage: _database_drop (db name)"
        return
    fi
    if [ "$1" == $PRODUCTION_DB ]; then
        _err "Script asking to drop name of production database! Refusing"
        exit 1
    fi
    _database_set_profile test
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "DROP DATABASE $1;"
    RESULT=$?
    return $RESULT
}



# =====
# Database utility functions
# =====

#####
# Prints a list of databases in one of the profiles
# Arguments:
#    $1: either 'prod' or 'test'
# Return:
#    None
#####
database_list() {
    if [ -z "$1" ]; then
        echo "Usage: database_list (prod|test)"
        return
    fi
    _database_set_profile $1
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d '|' -f 1 | sed 's/[ ]*//g;/^$/d' | sort -n
    _database_unset
}

#####
# Test the connectivity to a database with a SELECT 1; statement
# Arguments:
#    None
# Return:
#    Exit code of psql
#####
database_test_connectivity() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: database_test_connectivity (prod|test) (db name)"
        return
    fi
    _database_set_profile $1
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER $2 -c "SELECT 1;"
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then
        _info "SUCCESS"
    else
        _err "Fail to connect"
    fi
    _database_unset
    return $RESULT
}


#####
# Backup a database to file
# Arguments:
#    $1: either 'prod' or 'test'
#    $2: name of database
#    $3: file
# Return:
#    None
#####
database_backup() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: database_backup (prod|test) (db name) (file)"
        return
    fi
    _database_set_profile $1
    pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER --format=c --file="$3" $2
    success="$?"
    if [ "$success" -eq 0 ]; then
        _info "SUCCESS. Backup to '$3': complete"
    else
        _err "database_backup failed to complete"
    fi
    _database_unset
    return $success
}


#####
# Restore database to TEST_DB
# Arguments:
#    None
# Return:
#    None
#####
database_restore_to_test() {
    if [ -z "$1" ]; then
        echo "Usage: database_restore_to_test (file)"
        return 1
    fi
    if [ ! -f "$1" ]; then
        _err "$1 does not exist"
        return 1
    fi

    _database_set_profile test

    # Lets make a tmp database first just in case it goes wrong
    TMP_NAME=${TEST_DB}`date '+%Y%m%d%H%M%S'`
    if _database_exists test "$TMP_NAME"; then
        _database_drop "$TMP_NAME"
    fi
    _info "Creating tmp database for restoration"
    createdb -h $DB_HOST -p $DB_PORT -U $DB_USER -T template0 $TMP_NAME
    _exitIfError "Failed to create tmp database '$TMP_NAME'."
    _info "Createdb successful"

    # Restore
    _info "Restoring to tmp database"
    pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER --dbname=$TMP_NAME $1
    _exitIfError "Failed to restore to $TMP_NAME. TEST_DB '$TEST_DB' is un-touched."
    _info "Restore to tmp database succesful"

    # Remove previous TEST_DB
    if _database_exists test "$TEST_DB"; then
        _info "Attempting to drop old test database"
        _database_drop "$TEST_DB"
        _exitIfError "Failed to drop the previous TEST_DB '$TEST_DB'. Aborting"
    else
        _info "There is no previous instance of TEST_DB '$TEST_DB'. This is will be the first!"
    fi

    _info "Renaming tmp database to TEST_DB '$TEST_DB'"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "ALTER DATABASE $TMP_NAME RENAME TO $TEST_DB"
    _exitIfError "Failed to rename database. TEST_DB '$TEST_DB' is un-touched."
    _info "SUCCESS. TEST_DB '$TEST_DB' has been restored"

    _database_unset
}


#####
# Utility to let you know if all the environment variables have been set
# Arguments:
#    None
# Return:
#    0 if successful, 1 if anything is missing
#####
config_test() {
    is_valid=true
    for var in "${_backup_params[@]}"; do
        if [ -z "${!var}" ]; then
            _err "Missing environment variable $var"
            is_valid=false
        fi
    done

    if $is_valid; then
        _info "Check complete. All variables are set"
        return 0
    else
        return 1
    fi
}


#####
# Utility to unset all the environment variables so that in a script you can ensure nothing is left in memory at the end
# Arguments:
#    None
# Return:
#    None
#####
config_clear() {
    for var in "${_backup_params[@]}"; do
        unset $var
    done
}



####
# [ALWAYS RUN] 
# Handle GnuPG 1 and 2 differences for container by setting GPG_OPTS
#
# Default console entry behaviour in GPG 2 is a bit more secure but incompatible with
# how we use it inside a container. 
####
is_gpg2=$(gpg --version | grep "gpg (GnuPG)" | sed 's/gpg (GnuPG) //')
GPG_OPTS="--batch"
if [ "${is_gpg2:0:1}" = "2" ]; then
    # The first char is a 2 so it must be version 2
    # Add the entry mode to loopback bit
    GPG_OPTS="${GPG_OPTS} --batch --pinentry-mode loopback"
fi
export GPG_OPTS



#####
# Upload a backup using duplicity
# Arguments:
#    $1: Encrypt key id from GPG
#    $2: Source location to backup
#    $3: Destination using duplicity backend notation (see duplicty --help)
#####
dup_upload() {
    _info "Backup to $3"
    # Set the PASSPHRASE variable which is the var that GnuPG expects
    export PASSPHRASE=$ENCRYPT_PASSWORD
    duplicity full \
        --gpg-options "${GPG_OPTS}" \
        --verbosity notice \
        --encrypt-key "$1" \
        --num-retries 3 \
        --asynchronous-upload \
        --volsize 10 \
        --force \
        "$2" "$3"
    success=$?
    unset PASSPHRASE
    return $success
}

#####
# Enforces a rolling window backup policy on a duplicity backup store
# Arguments:
#    $1: Number of (time-unit) to keep in positive integer
#    $2: Duplicity time unit such as "D", "W", "M"
#    $3: Backup destination using duplicity backend notation (see duplicty --help)
#####
dup_cleanup() {
    _info "Cleaning older than "$1$2" for $3"
    # Set the PASSPHRASE variable which is the var that GnuPG expects
    export PASSPHRASE=$ENCRYPT_PASSWORD
    duplicity remove-older-than "$1$2" \
        --gpg-options "${GPG_OPTS}" \
        --verbosity notice \
        --force \
        "$3"
    success=$?
    unset PASSPHRASE
    return $success
}


#####
# Short cut for running duplicity to do a restoration
# Arguments:
#    $1: The backup to restore using duplicity backend notation (see duplicity --help)
#    $2: Destination location to restore to
#####
dup_restore() {
    _info "Restoring to $2"
    # Set the PASSPHRASE variable which is the var that GnuPG expects
    export PASSPHRASE=$ENCRYPT_PASSWORD
    duplicity restore --verbosity notice \
        --gpg-options "${GPG_OPTS}" \
        --force \
        "$1" "$2"
    success=$?
    unset PASSPHRASE
    return $success
}




