#!/bin/sh

# Make a simple 'demo_prod' database
createdb -U postgres -T template0 demo_prod
psql -U postgres demo_prod <<EOF
CREATE TABLE demo_table ( id integer );
INSERT INTO demo_table VALUES(1);
EOF

# Import GPG key. Make your own please.
export PASSPHRASE=demo
gpg --batch --pinentry-mode loopback --import /workspace/demo/DemoEncryptKey.private.key
#echo "F50A7BBA7E9E3792627CB0DC53EC22E53738F12F:6:" | gpg --import-ownertrust
gpg --import-ownertrust /workspace/demo/DemoEncryptKey-ownertrust.txt

# Add to crontab
crontab -l > tmp.cron
cat >> tmp.cron <<EOF
1 2 * * * bash /workspace/swift_backup.bash /workspace/demo/demo.params
15 2 * * * bash /workspace/update_test_db_from_backup.bash /workspace/demo/demo.params
EOF

crontab tmp.cron


# Start cron
cron

# Run each manually once
bash /workspace/swift_backup.bash /workspace/demo/demo.params
bash /workspace/update_test_db_from_backup.bash /workspace/demo/demo.params
