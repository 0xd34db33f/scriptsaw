#!/bin/bash
# Ryan C. Moon
# 2014-01-23
# update.sh
# default ubuntu "unattended updates" script

/usr/bin/apt-get update;
/usr/bin/apt-get -y autoremove;
/usr/bin/apt-get -y upgrade;
/usr/bin/apt-get -y dist-upgrade;
/usr/bin/apt-get -y autoremove;
/usr/sbin/update-grub
