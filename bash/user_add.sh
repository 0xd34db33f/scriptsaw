#!/bin/bash
# user_add.sh
# Ryan C. Moon
# 2012-09-12
# Creates a new user in ubuntu with the ssh key setup below (optional).
# usage: ./user_add ryan

USER="$1"
KEY=""

useradd -s /bin/bash -m $USER
passwd $USER
mkdir -p /home/$USER 
chown $USER:$USER /home/$USER 
mkdir /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
echo "$KEY" >> /home/$USER/.ssh/authorized_keys
chmod 600 /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER
