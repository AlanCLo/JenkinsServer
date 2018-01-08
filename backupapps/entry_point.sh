#!/bin/sh
#
# Entry point to container so that this is what is executed everytime it starts
# This should include:
#    Loads any (new) keys listed in secrets/ 
#    Install cron schedule
#
# Cron is the actual main program this container is presenting

KEY_SUFFIX=.private.key
OWNER_SUFFIX=.ownertrust.txt

for key_file in `ls secrets/*$KEY_SUFFIX`; do
    key_name=${key_file%$KEY_SUFFIX}
    key_owner="$key_name$OWNER_SUFFIX"
    echo "Importing GPG key: $key_name, with ownertrust $key_owner"
    gpg --import $key_file
    gpg --import-ownertrust $key_owner
done

crontab crontab.file

cron -f
