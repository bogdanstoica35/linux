#!/bin/bash

# created by Bogdan Stoica on 06/10/2016
# email: bogdan@898.ro.ro
# web: https://898.ro

### apache 2.x log searcher

## search the last N entries of your apache access_log for:
#
# - ip (visitor's ip)
# - agent (visitor's browser user agent)
# - url (most accessed urls of your website)
#
##

## Usage example:
# - apache-ls ip 1000 /path/to/access_log - will find the top IPS accessing your site in the last 1000 lines of your apache log
# - apache-ls agent 1000 /path/to/access_log - will find the top 'User Agents (browser)' of the users accessing your site in the last 1000 lines of your apache log
# - apache-ls url 1000 /path/to/access_log - will find the top URLs (pages) accessed by the user of your site in the last 1000 lines of your apache log
##

querytype=$1
nooflines=$2

if [ "$3" == "" ]; then
  logfile=""
else
  logfile="$3"
fi

if [ "$querytype" = "ip" ]; then
  tail -n $nooflines $logfile | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n
elif [ "$querytype" = "agent" ]; then
  tail -n $nooflines $logfile | awk -F\" '{print $6}'| sort -n | uniq -c | sort -n
elif [ "$querytype" = "url" ]; then
  tail -n $nooflines $logfile | awk -F\" '{print $2}'| sort -n | uniq -c | sort -n
fi

