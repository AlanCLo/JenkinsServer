#!/bin/sh

apt-get update
apt-get upgrade
apt-get install -y vim
apt-get install -y python-pip gnupg2 duplicity
#apt-get install -y postgresql postgresql-contrib
pip install python-swiftclient python-keystoneclient


