# Backup #

Sub-system featuring rolling-window full backup to SWIFT and supporting copy-of-prod test databases for database applications. Every application you wish to apply this to requires its own *params* file, and associated lines in crontab.

Example: 2:01am nightly schedule to backup for "blahapp"
```bash
1 2 * * * bash /workspace/swift_backup.bash /workspace/blahapp.params
```

Uses:
 * Bash script
 * Cron
 * Duplicity
 * GPG2
 * OpenStack SWIFT

Currently supports:
 * PostresSQL
 
- - - - 
## Setup Instructions ##
1. Clone this folder in prefered location. e.g. /workspace
2. Install dependencies. 
3. Copy template.params and fill in the parameters
   - [ ] Production database connection details
   - [ ] Test database connection details
   - [ ] GPG encryption key
   - [ ] Openstack SWIFT tenancy details
   - [ ] Backup policy settings for daily, weekly and monthly rolling window backup
4. Setup cron to run once per day at preferred time

- - - -
## How To's ##

### Installing software dependencies ###

TODO

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
# To list keys on the system
gpg -k
```
Change _Name-Real_, _Name-Email_, _Passphrase_ and other settings to your preference. Don't forget to make note of the Passphrase!!

##### Not enough entropy, this is a VM #####
VMs have trouble getting enough entropy for generating these secure keys due to lack of real devices the kernel can read from to get random values.

Install 'haveged' to remedy this.
 * Debian/Ubuntu: sudo apt-get install haveged && haveged -F
 * Docker: docker run --privileged -d harbur/haveged
    
```bash
# Tells you how much entropy you have on the system
cat /proc/sys/kernel/random/entropy_avail
```



