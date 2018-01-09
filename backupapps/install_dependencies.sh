#!/bin/sh
#
# Installs software dependencies on ubuntu
# Is a separate script so that you can have a straight install on OS or as docker image

set -x

# Core
apt-get update
apt-get install -y --no-install-recommends gcc python-dev python-pip gnupg2 duplicity cron
pip install --upgrade --force pip
pip install setuptools 
pip install python-swiftclient 
pip install python-keystoneclient

# Extras: PostgreSQL 10
apt-get install -y --no-install-recommends wget
echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y --no-install-recommends postgresql-10 

