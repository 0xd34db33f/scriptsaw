#!/bin/bash
# Easy OpenVPN deploy script, run as root
# Will listen on port 28802 by default
# Configs live in /etc/openvpn
# Source lives in /root/src/openvpn* and /root/src/easy-rsa/
# Reference: http://openvpn.net/index.php/open-source/documentation/howto.html#install

OPENVPN_CONF_URL="http://CHANGEME/openvpn-server.conf"
export EASY_RSA="/root/src/easy-rsa/easy-rsa/2.0"

# Mandatory Yums
yum install gcc make lzo lzo-devel openssl openssl-devel pam pam-devel

# Validate source directory
mkdir /root/src

# Download and install OpenVPN
cd /root/src
wget "http://swupdate.openvpn.org/community/releases/openvpn-2.3.2.tar.gz" -O /root/src/openvpn-current.tar.gz
tar -zxvf openvpn-current.tar.gz
cd /root/src/openvpn-2.3.2
./configure && make && make install

# Download EasyRSA
cd /root/src
git clone https://github.com/OpenVPN/easy-rsa.git

# Setup easy RSA files
cd $EASY_RSA
echo "export EASY_RSA=\"$EASY_RSA\"
export OPENSSL=\"openssl\"
export PKCS11TOOL=\"pkcs11-tool\"
export GREP=\"grep\"
export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`
export KEY_DIR=\"$EASY_RSA/keys\"
export PKCS11_MODULE_PATH=\"dummy\"
export PKCS11_PIN=\"dummy\"
export KEY_SIZE=4096
export CA_EXPIRE=3650
export KEY_EXPIRE=3650
export KEY_COUNTRY=\"US\"
export KEY_PROVINCE=\"CA\"
export KEY_CITY=\"Redwood City\"
export KEY_ORG=\"Thunderdomes\"
export KEY_EMAIL=\"me@myhost.mydomain\"
export KEY_OU=\"Secretary of Calendars\"
export KEY_NAME=\"`hostname`\"
" > $EASY_RSA/vars

# Source vars
source $EASY_RSA/vars

# Clean and build CAs, certs for server and client, and dh suite
# Answer yes to all questions
$EASY_RSA/clean-all
$EASY_RSA/build-ca
$EASY_RSA/build-key-server `hostname`
$EASY_RSA/build-key client1
$EASY_RSA/build-dh

# Fetch configs
wget "$OPENVPN_CONF_URL" -O $EASY_RSA/server.conf

# copy everything into place
mkdir /etc/openvpn
cp -R $EASY_RSA/* /etc/openvpn

# Ending notes
echo ""
echo "** Make sure to edit the /etc/openvpn/server.conf file to point at the correct keys, the default key generated is `hostname`.key, not server.key. **"
echo "" 
echo "Test the setup with openvpn <server conf file>"
echo ""
echo "Firewall Settings:"
echo "iptables -A INPUT -p udp --dport 28802 -j ACCEPT"
echo "iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT"
echo "iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT"
echo "iptables -A FORWARD -j REJECT"
echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o venet0 -j MASQUERADE"
echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $(/sbin/ifconfig venet0:0 | grep 'inet addr:' | awk '{print $2}' | sed 's/:/\ /g' | awk '{print $2}')"
echo ""

