#!/bin/bash
# spamassassin_autogenerate_whitelist.sh
# Ryan C. Moon
# 2015-09-23
# Autogenerates a whitelist for SpamAssassin based on all your senders. 
# This should be automated to run via crontab.
# REQUIRES Postfix setup to use MAILDIR
# REQUIRES SpamAssassin to include the CUSTOM_WHITELIST file in local.cf. 

CUSTOM_WHITELIST=/etc/spamassassin/auto_whitelist.cf

for x in $(ls /home); do find /home/$x/Maildir/.Sent/ -type f -exec grep -Eo "^To:.*$" {} \; | sed 's/To:\ //g' | grep -Eo "[A-Za-z0-9]+@[^.]+\.[a-z]{2,6}" | sort -u; done | sort -u > /tmp/senders.txt

echo "Whitelist has : $(wc -l /tmp/senders.txt) senders.."

for x in $(cat /tmp/senders.txt); do echo "whitelist_to $x" >> $CUSTOM_WHITELIST; echo "whitelist_from $x" >> $CUSTOM_WHITELIST; done

echo "Restarting Spamassassin.."
service spamassassin restart

echo "Done.."
