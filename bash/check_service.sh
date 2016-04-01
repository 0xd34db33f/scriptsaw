#!/bin/bash -l
# check_service.sh
# Ryan C. Moon
# 2016-03-29
# Validates $service is running. If it is not, emails notification person.

NOTIFICATION_EMAIL=""
LOG_FILE=/var/log/service.log?
PROCESS_NAME="someservice"
PROCESS_PIDS=$(ps aux | grep $PROCESS_NAME | grep -v grep | grep -v $0 | awk '{print $2}' | wc -w)

if [ $PROCESS_PIDS -lt 1 ]
then
	echo "[!] $PROCESS_NAME is not running! Restarting.."
	/usr/sbin/service $PROCESS_NAME restart
	sleep 15
	( echo "$PROCESS_NAME was dead. It has been restarted. Log:" && tail -30 $LOG_FILE) | /usr/bin/mailx -s "[$(hostname)] !!! $PROCESS_NAME died $(date '+%Y-%d-%m %H:%M')" $NOTIFICATION_EMAIL
else
	echo "[.] $PROCESS_NAME is running, doing nothing. Exit!"
fi
