#!/bin/bash
# suricata_update.sh
# Ryan C. Moon
# 2013-08-13
# Executed as root, should install Suricata with friends on Ubuntu 12.04 LTS.

/usr/bin/apt-get -y install linux-headers-$(uname -r) pkg-config build-essential make flex libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev autoconf libc6-dev ncurses-dev automake libtool bison tcl-dev tk-dev blt-dev magic dkms libpcre3-dev libpcap-dev libcap-ng-dev libnet1-dev git-core subversion libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libyaml-0-2  libcap-ng0 git libmagic-dev libnspr4 libnspr4-dev

# install LuaJIT
cd /root/src
rm -rf /root/src/LuaJIT*
/usr/bin/wget http://luajit.org/download/LuaJIT-2.0.0.tar.gz
/bin/tar -zxf LuaJIT-2.0.0.tar.gz
cd LuaJIT-2.0.0
/usr/bin/make && /usr/bin/make install

# Install PFRing
# DISABLED due to module locking in /etc/rc.local, line "/sbin/sysctl -w kernel.modules_disabled=1"
#rmmod pf_ring
#cd /root/src
#rm -rf pfring-svn*
#svn export https://svn.ntop.org/svn/ntop/trunk/PF_RING/ pfring-svn-latest
#cd pfring-svn-latest/kernel
#/usr/bin/make && /usr/bin/make install
#cd ../userland/lib
#./configure --prefix=/usr/local/pfring && /usr/bin/make && /usr/bin/make install
#cd ../libpcap-1.1.1-ring
#./configure --prefix=/usr/local/pfring && /usr/bin/make && /usr/bin/make install
#cd ../tcpdump-4.1.1
#./configure --prefix=/usr/local/pfring && /usr/bin/make && /usr/bin/make install
#/bin/echo '/usr/local/pfring/lib' > /etc/ld.so.conf.d/pfring.conf
#/sbin/ldconfig

# Install Suricata
cd /root/src
rm -rf /root/src/oisf
/usr/bin/git clone git://phalanx.openinfosecfoundation.org/oisf.git
cd oisf
git clone https://github.com/ironbee/libhtp.git -b 0.5.x
./autogen.sh
./configure --enable-pfring --enable-luajit --with-libpfring-includes=/usr/local/pfring/include --with-libpfring-libraries=/usr/local/pfring/lib --with-libpcap-includes=/usr/local/pfring/include --with-libpcap-libraries=/usr/local/pfring/lib --with-libnss-libraries=/usr/lib --with-libnss-includes=/usr/include/nss/ --with-libnspr-libraries=/usr/lib --with-libnspr-includes=/usr/include/nspr --with-libluajit-includes=/usr/local/include/luajit-2.0/ --with-libluajit-libraries=/usr/lib/x86_64-linux-gnu/
/usr/bin/make clean && /usr/bin/make && /usr/bin/make install && /sbin/ldconfig
/usr/local/bin/suricata -V
