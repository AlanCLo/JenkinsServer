# Backup #

Sub-system featuring rolling-window full backup to SWIFT and supporting "mirror prod" test databases for database applications. Built around __duplicity, cron and GPG using bash scripts__. Can be setup on a server or as docker container.

## Overview of contents ##

| Folder | Description |
| --- | --- |
| apps/ | Where cron scripts will search for app profiles that specific backup for each application to backup. |
| scripts/ | Bash scripts source code. |
| secrets/ | Default location for where GPG keys and OpenStack RC profiles can be stored. |

__Recommended Extras__

| Folder | Description |
| --- | --- |
| data/ | Where database dumps or similar artefacts to backup can be stored for scripts to pick up. This way you have a local backup you can immediately access. |
| filesystem/ | When you want to backup to local filesystem accessible by the server by using "file://" backend in duplicity. |
| restore/ | Default folder to restore backups to. |

If the whole __backupapps/__ is a mounted volume on your server with an appropriate device (for example VM Volume), this can make disaster recovery of your backup server simpler. 

## Quick start: Using Container ##

```bash
# Assumes Docker installed.

# Build 'backupapps' container
make
# Starts container
make run
```

What you'll get:
* Demo apps will be backup to local filesystem with standard policies, using demo GPG key
* Cron schedule is setup and good to go
* backupapps/ is a volume to the container so the contents are linked
* Default backup policies are:
  * Daily up to last 7 days
  * Weekly up to last 4 weeks
  * Monthly up to last 12 months

Review the [Makefile](Makefile). Its just a series of short cuts to docker commands.

NOTE: Default make parameters link to a postgres container instance named 'postgres'. If you do not have that, just set that to blank before you run. This is a good way to test that you are reading this. Refer to [../postgresql](postgresql) if you want one. 

__WHAT NEXT?__
* Get your own GPG key setup. See GPG section for more details.
* Setup your application backup. See [How to backup an app](#how-to-backup-an-app)


## Setup: Install on host server (not container) ##

This is a Ubuntu 16.04 system.

1. Checkout the backupapps/ folder from git repo to preferred location on file system. 
2. Run install\_dependencies.sh 
3. Setup/import GPG keys for your backup
4. Setup crontab (set/append) with [crontab.file](crontab.file)

## How to backup an app ##

* Add a sub-folder under apps/
* Cron schedule will pick up all \*.profile and \*.mirror scripts to process
* Grab a copy of whatever you need from [apps/templates](apps/templates). You can:
  * Backup a PostgreSQL database - [dbprofile.template](apps/templates/dbprofile.template)
  * Backup files from a folder - [fileprofile.template](apps/templates/fileprofile.template)
  
You can have as many profiles for your app if you have multiple databases and/or folders you need to backup. __Give each a different DEST\_PREFIX__.






4. How to template
5. How to GPG
6. Debug and extensions





**Example**:

"blahapp" is a django app, all required connection details and backup policy is stored in /workspace/blahapp.params
 * Backup very night at 2:01am to SWIFT
 * Get a fresh test copy of the production database every night at 2:15am
```bash
1 2 * * * bash /workspace/swift_backup.bash /workspace/blahapp.params
15 2 * * * bash /workspace/update_test_db_from_backup.bash /workspace/blahapp.params
```
Repeat for each other application you wish to apply to.

Requires:
 * Bash script
 * Cron
 * Duplicity
 * GPG2
 * OpenStack SWIFT

Currently supports:
 * PostresSQL


## Setup Instructions ##
1. Clone this folder in prefered location. e.g. /workspace
2. Install software dependencies. (See how-to)
3. Copy template.params and fill in the parameters
   - [ ] Production database connection details
   - [ ] Test database connection details
   - [ ] GPG encryption key
   - [ ] Openstack SWIFT tenancy details
   - [ ] Backup policy settings for daily, weekly and monthly rolling window backup
4. Setup cron to run once per day at preferred time for swift_backup.bash and update_test_db_from_backup.bash as per example above

**Notes**: 
 * It is fine to run the scripts manually outside of cron to do a backup or restore to test.
 * If you are setting this up for the first time: create new GPG keys, otherwise import the existing key to talk to existing backups
 * See How To's below for practical things to do to get this going.

## How To's ##

### Installing software dependencies ###
Review contents of _install-dependencies.sh_. If you are on a debian-based system, should ble able to execute it.
```bash
sudo install-dependencies.sh
```

### GPG Key ###
#### Creating a GPG2 Key ####
Consult the internet.

But here is an example:
```bash
cat > gpg.encrypt.script <<EOF
Key-Type: RSA
Key-Length: 2048
Name-Real: EncryptKey
Name-Comment: For encrypting data in swift
Name-Email: email@email.com
Expire-Date: 0
Passphrase: (supersecretpassword)
%commit
%echo done
EOF
gpg --batch --generate-key gpg.encrypt.script
# List keys and signatures on the system. Grab the key and sig for the params
gpg --list-signatures
```
Change _Name-Real_, _Name-Email_, _Passphrase_ and other settings to your preference. Don't forget to make note of the Passphrase!!

#### Not enough entropy, this is a VM ####
VMs have trouble getting enough entropy for generating these secure keys due to lack of real devices the kernel can read from to get random values.

Install 'haveged' to remedy this.
 * Debian/Ubuntu: sudo apt-get install haveged && haveged -F
 * Docker: docker run --privileged -d harbur/haveged
    
```bash
# Tells you how much entropy you have on the system
cat /proc/sys/kernel/random/entropy_avail
```

#### Import/Export keys ####
You want to make sure you have a copy of the key to restore your backup in case everything else is on fire. 

Based on the above example:

**Exporting:**
```bash
gpg --export-secret-key -a "EncryptKey" > EncryptKey.private.key
gpg --export-ownertrust > EncryptKey-ownertrust-gpg.txt

# For containers you need loopback
gpg --pinentry-mode loopback --export-secret-key -a "EncryptKey" > EncryptKey.pri
gpg --export-ownertrust > EncryptKey-ownertrust-gpg.txt
```

**Importing**
```bash
gpg --import EncryptKey.pri
gpg --import-ownertrust EncryptKey-ownertrust-gpg.txt

# For containers you need loopback
gpg --pinentry-mode loopback --import EncryptKey.pri
gpg --import-ownertrust EncryptKey-ownertrust-gpg.txt
```
Without the ownertrust step, keys you import aren't trusted, and by default all gpg commands will exit with error.

You don't have to have the ownertrust.txt files. If you don't have it, you can still import the key and pick one of these alternatives:
```bash
# Alternative 1: Set trust manually
gpg --edit-key (name of key)
# then follow the prompts to give [ultimate] trust

# Alternative 2: Script that trusts ALL known keys without trusted owner 
gpg –list-keys –fingerprint –with-colons | sed -E -n -e ‘s/^fpr:::::::::([0-9A-F]+):$/\1:6:/p’ | gpg --import-ownertrust
```

This is a summary based on current searches and my limited understanding. Consult the internet for the latest on gpg2 best practices.

### Logging ###
I recommend redirecting stdout and stderr to a log file for diagnosis in the future. Use logrotate to auto maintain log file capacity. 

Example:

The following will run logrotate at 2:30am every night. The configuration rotates if it exceeds 100k bytes by moving the filename. It keeps a window of 10 rotations.

The crontab:
```bash
1 2 * * * bash /workspace/swift_backup.bash /workspace/blahapp.params 2>&1 >> /workspace/logs/backup.log 
15 2 * * * bash /workspace/update_test_db_from_backup.bash /workspace/blahapp.params 2>&1 >> /workspace/logs/update.log
30 2 * * * logrotate /workspace/backup_logrotate.conf
```

backup\_logrotate.conf
```
/workspace/logs/*.log {
	missingok
	notifempty
	size 100k
	copytruncate
	rotate 10
}
```

## More on Scripts and Debugging ##

> I hate your scripts
>> Ok.

I assume that this isn't going to work out of the box everywhere so I designed the scripts such that your can source them in bash and run various utility functions to diagnose what's wrong. Do this:
```bash
# Get the environment variables for the app you are working on
source (whichever app.params)

# Load the utility functions
source utility.bash
```
You now have a number of bash functions starting with "database\_" you can tab-complete to show what you can do. Worst-case scenario you can pick a line or two out of the bash functions in the code to get the job done.

List of useful functions:
```bash
# Tells you which environment variable you haven't got yet if any
config_test

# List name of each database on prod server or test server
database_list (prod|test)

# Executes "SELECT 1;" on the given prod or test server and database name
database_test_connectivity (prod|test) (db name)

# Backup the named database on prod or test server to file
database_backup (prod|test) (db name) (file)

# Shortcut to run database_backup on PRODUCTION_DB as specified in environment variable
database_backup_production

# Create/Recreate TEST_DB from file. Only replaces database if restoration successful.
database_restore_to_test (file)
```

When you are getting a new setup and application going, you should be able to run each of these functions on their own. Of course you should run the swift\_backup.bash and update\_test\_db\_from_backup.bash manually before setting up cron


## Run as container ##
You can consider running this as a container with docker. 

One use case is to avoid dependency hell for your build server where multiple projects demand different versions of PostgreSQL, pgp2, or something like that. In which case, edit the base image of the Dockerfile (currently postgres:latest) to your liking and build the image.

```bash
docker build -t dupimg .
docker run -d -it --name mybackup dupimg
```
Change the image name (dupimg) and instance name (mybackup) to your liking.

Use it to load the demo to see what it looks like functioning
```bash
# Setup the demo project, with imported demo key and runs a backup & restore
# Note taht demo cheats and backups to filesystem instead of swift
docker exec mybackup /workspace/demo/demo_setup.sh

# Enter the instance to look at the whats going on
docker exec -it mybackup /bin/bash
```

Consider these variants of running the image:
```bash
# You have a container running PostgreSQL named 'postgres' you want this to talk to
# Use the --link flag
docker run -d -it --name mybackup --link postgres:postgres dupimg

# You have a folder on the host /backup that you want this to use as the local backup_folder before going to SWIFT
# Use the -v flag
docker run -d -it --name mybackup -v /backup:/workspace/backup_folder dupimg
```
You can use both variants of course. Consult the internet for other ways to use containers.

