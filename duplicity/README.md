# Backup #

Sub-system featuring rolling-window full backup to SWIFT and supporting copy-of-prod test databases for database applications. Every application you wish to apply this to requires its own **params** file, and associated lines in crontab.

The main idea is there is that you have:
 1. A production database for your application that you wish to backup with a rolling window policy of daily, weekly and monthly backups.
 2. For testing, another test database is needed and is always a copy of production based on the last backup.


Example: 
"blahapp" is a django app, all required connection details and backup policy is stored in /workspace/blahapp.params
Backup very night at 2:01am to SWIFT
Get a fresh test copy of the production database every night at 2:15am
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
2. Install dependencies. 
3. Copy template.params and fill in the parameters
   - [ ] Production database connection details
   - [ ] Test database connection details
   - [ ] GPG encryption key
   - [ ] Openstack SWIFT tenancy details
   - [ ] Backup policy settings for daily, weekly and monthly rolling window backup
4. Setup cron to run once per day at preferred time for swift_backup.bash and update_test_db_from_backup.bash as per example above

**Note**: It is fine to run the scripts manually outside of cron to do a backup or restore to test.
See How To's below for practical things to do to get this going.

## How To's ##

### Installing software dependencies ###
Review contents of install-dependencies.sh
If you are on a debian-based system, should ble able to execute it.



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
gpg --export-secret-key -a "EncryptKey" > EncryptKey.pri

# For containers you need loopback
gpg --pinentry-mode loopback --export-secret-key -a "EncryptKey" > EncryptKey.pri
```

**Importing**
```bash
gpg --allow-secret-key-import --import EncryptKey.pri

# For containers you need loopback
gpg --pinentry-mode loopback --allow-secret-key-import --import EncryptKey.pri
```


### More on Scripts and Debugging ###

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
database_list (prod|test)
database_test_connectivity (prod|test) (db name)
database_backup (prod|test) (db name) (file)
database_backup_production
database_restore_to_test
config_test
```

When you are getting a new setup and application going, you should be able to run each of these functions on their own. Of course you should run the swift\_backup.bash and update\_test\_db\_from_backup.bash manually before setting up cron




