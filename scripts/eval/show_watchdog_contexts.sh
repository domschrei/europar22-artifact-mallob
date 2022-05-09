#!/bin/bash

if [ -z $1 ]; then
	echo "Provide a log file."
	exit
fi

cat "$1"|grep Watchdog |awk '{print $2}' > _watchdogranks

for rank in $(cat _watchdogranks); do 
	cat "$1"|awk '$2 == '$rank|grep -B10 -A3 Watchdog
done

rm _watchdogranks

