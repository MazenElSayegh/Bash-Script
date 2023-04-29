#!/bin/bash
##Script to be executed every one minute to monitor system logs
##Exit Codes
        # 0: Success
        # 1: Script not runned by root
##check if script not runned by root
[ $(/usr/bin/id -u) -ne 0 ] && exit 1

##Log every one minute
while(true)
do
[ $(uptime>>/var/log/system-load) ]
echo "working"
sleep 1m
done

exit 0
