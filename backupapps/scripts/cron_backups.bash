#!/bin/bash
#
# Runs backup on each app defined by a .profile in the apps folder
#

for app in $(find apps/ -name "*.profile"); do 
    scripts/backup_app.bash $app
done
