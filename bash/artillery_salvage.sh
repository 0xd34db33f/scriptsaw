#!/bin/bash
# artillery_salvage.sh
# Ryan C. Moon
# 2014-03-21
# Reads syslog on the hour and prints all relevant artillery attacks to a log in /tmp.. or wherever.
#
# current log filename: /var/log/artillery/artillery.log
# past log filenames: /var/log/artillery/artillery-DD-MM-YY.log
# 
# Log keep time is 30 days.
# This should be run at 00:00:00.

# rename the current log to the old log
mv /var/log/artillery/artillery.log /var/log/artillery/artillery-$(date "+%d-%m-%Y").log

# echo preamble
echo "# $(ifconfig eth0 | grep "inet addr" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1) Honeypot - Daily Attack Feed" > /var/log/artillery/artillery.log
echo "# Columns: count,attacker_ip,target_port" >> /var/log/artillery/artillery.log

# capture current log
grep "Artillery has detected" /var/log/syslog | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[^\x0d]+port: [0-9]{1,5}" | awk '{print "," $1 "," $9}' | sort -n | uniq -c >> /var/log/artillery/artillery.log

# clean up old logs
find /var/log/artillery -type f -mtime +30 -exec rm -rf {} \;

# copy the current log to tmp so we can grab it
cp /var/log/artillery/artillery.log /tmp/

