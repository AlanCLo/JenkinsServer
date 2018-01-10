#!/bin/bash
#
# Runs backup on each app defined by a .profile in the apps folder
#

SCRIPT_HOME=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
APPS=$SCRIPT_HOME/../apps

for app in $(find "$APPS" -name "*.profile"); do 
    $SCRIPT_HOME/backup_app.bash $app
done
