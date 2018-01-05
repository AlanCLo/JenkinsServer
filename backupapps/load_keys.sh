#!/bin/sh
#
# Loads any keys listed in secrets/ 

KEY_SUFFIX=.private.key
OWNER_SUFFIX=.ownertrust.txt

for key_file in `ls secrets/*$KEY_SUFFIX`; do
    key_name=${key_file%$KEY_SUFFIX}
    key_owner="$key_name$OWNER_SUFFIX"
    echo "Importing GPG key: $key_name, with ownertrust $key_owner"
    gpg --import $key_file
    gpg --import-ownertrust $key_owner
done
