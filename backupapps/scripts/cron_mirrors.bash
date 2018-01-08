#!/bin/bash
#
# Runs backup on each app defined by a .profile in the apps folder
#

for app in $(find apps/ -name "*.mirror"); do 
    scripts/mirror_test_db.bash $app
done
