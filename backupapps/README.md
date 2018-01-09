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
* Get your own GPG key setup. See [GPG](#how-to-gpg) section for more details.
* Setup your application backup. See [How to backup an app](#how-to-backup-an-app)


## Setup: Install on host server (not container) ##

This is a Ubuntu 16.04 system.

1. Checkout the backupapps/ folder from git repo to preferred location on file system. 
2. Run sudo install\_dependencies.sh 
3. Setup/import GPG keys for your backup
4. Setup crontab by adding contents of [crontab.file](crontab.file)

## How to backup an app ##

* Add a sub-folder under apps/
* Cron schedule will pick up all \*.profile and \*.mirror scripts to process
* Grab a copy of whatever you need from [apps/templates](apps/templates). You can:
  * Backup a PostgreSQL database - [dbprofile.template](apps/templates/dbprofile.template)
  * Backup files from a folder - [fileprofile.template](apps/templates/fileprofile.template)
  
You can have as many profiles for your app if you have multiple databases and/or folders you need to backup. __Give each a different DEST\_PREFIX__.

Check out what is going on in [apps/database_demo](apps/database_demo) and [apps/files_demo](apps/files_demo) for a concrete example.

## How to GPG ##

### Creating a new GPG Key ###

If you are using the container, jump in the container so that you have gpg
```bash
make enter
```

Check out the contents of [secrets/DemoEncryptKey.gpg.script](secrets/DemoEncryptKey.gpg.script) as reference to making your own. You can do something like this:
```bash
$ cd secrets/
$ cat DemoEncryptKey.gpg.script
Key-Type: RSA
Key-Length: 2048
Name-Real: DemoEncryptKey
Name-Comment: Do not use for real situations
Name-Email: email@email.com
Expire-Date: 0
Passphrase: demo
%commit
%echo done
$ cp DemoEncryptKey.gpg.script mykey.gpg.script
$ vim mykey.gpg.script
### Update parameters to your liking, especially Passphrase
$ gpg --batch --generate-key gpg.encrypt.script
# List keys and signatures on the system. Grab the key and sig for the params
$ gpg --list-signatures
```

#### Not enough entropy, this is a VM/container ####
VMs have trouble getting enough entropy for generating these secure keys due to lack of real devices the kernel can read from to get random values.

Install 'haveged' to remedy this.
 * Debian/Ubuntu: sudo apt-get install haveged && haveged -F
 * Docker: docker run --privileged -d harbur/haveged
    
```bash
# Tells you how much entropy you have on the system
cat /proc/sys/kernel/random/entropy_avail
```

### Import/Export keys ###
You want to make sure you have a copy of the key to restore your backup in case everything else is on fire. 

Based on the above example:

**Exporting:**
```bash
gpg --export-secret-key -a "EncryptKey" > EncryptKey.private.key
gpg --export-ownertrust > EncryptKey-ownertrust-gpg.txt

# For containers and GPG2 you need loopback
gpg --pinentry-mode loopback --export-secret-key -a "EncryptKey" > EncryptKey.pri
gpg --export-ownertrust > EncryptKey-ownertrust-gpg.txt
```

**Importing**
```bash
gpg --import EncryptKey.pri
gpg --import-ownertrust EncryptKey-ownertrust-gpg.txt

# For containers and GPG2 you need loopback
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

This is a summary based on current searches and my limited understanding. Consult the internet for the latest on GPG2 best practices.

### Keys and Container ###

The container will import all keys under secrets/ when it starts. You just need to ensure there is a .private.key and .ownertrust.txt for each key you need.

If you have save a new key from elsewhere for your app to use, just stop/start the container
```bash
make stop && make start
```


## Scripts and Debugging ##

> I hate your scripts
>> Ok.
>> I like bash and assortment of snipplets from the internet though.

I assume that this isn't going to work out of the box everywhere so I designed the scripts such that your can source them in bash and run various utility functions to diagnose what's wrong. Do this:
```bash
# Get the environment variables for the app you are working on
source (whichever app.params)

# Load the utility functions
source scripts/utility.bash
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

# Create/Recreate TEST_DB from file. Only replaces database if restoration successful.
database_restore_to_test (file)

# Duplicity backup
dup_upload (encrypt key id) (src) (dest)

# Duplicity restore
dup_restore (backend) (restore dest)

```

