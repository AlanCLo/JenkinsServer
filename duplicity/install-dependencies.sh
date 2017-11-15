#!/bin/sh

apt-get update
apt-get upgrade -y
apt-get install -y vim
apt-get install -y python-pip gnupg2 duplicity
pip install python-swiftclient python-keystoneclient

if [ "$1" != "--nopsql" ]; then
	apt-get install -y postgresql postgresql-contrib
fi

