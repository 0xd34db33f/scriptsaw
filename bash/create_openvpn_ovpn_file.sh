#!/bin/bash
# Ryan C. Moon
# 2014-03-21
# Creates an .ovpn file for your OpenVPN client to use. Assumes the following parameters are correct:
# usage ./create_openvpn_ovpn_file.sh "mydevice" "myemailaddress@organizedvillainy.com"

DEVICE_NAME="$1"
EASY_RSA_DIRECTORY="/etc/openvpn/easy-rsa"
KEYS_DIRECTORY="/etc/openvpn/keys"
CERTS_DIRECTORY=""
EMAIL_CERT_RECIPIENT="$2"

# check if we have a device name
if [[ $1 == "" ]]
then
	echo "Usage: ./create_openvpn_cert.sh <device name> "
	exit 1
fi

# Move into the easy rsa directory to work
cd $EASY_RSA_DIRECTORY

# source vars
source $EASY_RSA_DIRECTORY/vars

# build the key and fill it out
$EASY_RSA_DIRECTORY/build-key $DEVICE_NAME

# copy the keys into the OpenVPN keys directory
/bin/cp $EASY_RSA_DIRECTORY/keys/$DEVICE_NAME.* $KEYS_DIRECTORY/

# Change to the OpenVPN Keys directory
cd $KEYS_DIRECTORY

# build OVPN file
/bin/echo "dev tun" > $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "client" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "remote organizedvillainy.com 1194" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "proto udp" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "comp-lzo" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "<ca>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/cat $KEYS_DIRECTORY/ca.crt >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "</ca>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "<cert>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/cat $KEYS_DIRECTORY/$DEVICE_NAME.crt >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "</cert>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "<key>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/cat $KEYS_DIRECTORY/$DEVICE_NAME.key >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn
/bin/echo "</key>" >> $KEYS_DIRECTORY/$DEVICE_NAME.ovpn

# Mail it to me..
/bin/echo "$DEVICE_NAME ovpn file.." | /bin/mailx -s "[certs] $DEVICE_NAME" -a $KEYS_DIRECTORY/$DEVICE_NAME.ovpn $EMAIL_CERT_RECIPIENT
