#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

calldir="$(pwd)"
cd "$basedir" 

# Extract program options from logs of rank zero
options=$(cat 0/log.0|head -10|grep "Program options")
# Extract number of clients from the program options
numclients=$(echo $options|grep -oE " -c=[0-9]+ "|grep -oE "[0-9]+")
# Find out which is the highest process rank
lastclient=$(echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
# Calculate the rank of the first client 
firstclient=$(($lastclient - $numclients + 1))

# Extract number of active jobs over time
cat 0/log.*|grep -E "sysstate.*jobs="|sed 's/jobs=//g'|awk '{print $1,$6}' > _active_jobs

# Extract all load events
cat */log.*|grep -oE "[0-9\.]+ [0-9]+ LOAD [01]"|sort -s -g > _load_events
# Convert load events into a time series of system utilization
cat _load_events|sort -s -g|awk '\
/LOAD 1/ {load+=1}\
/LOAD 0/ {load-=1}\
/LOAD/ {print $1,load/'$(($lastclient+1))'}' > _loads
# Calculate sliding averages of the utilization at different window sizes
for window in 1 15 60; do
    python3 scripts/eval/sliding_average.py _loads $window > _loads_slavg_$window
done

#cat */log.*|grep "LOAD 1"|sed 's/[()+#-]//g'|sed 's/:/ /g'|awk '{cs[$5][$6]+=1} END {for (j in cs) {for (i in cs[j]) {occs[cs[j][i]]+=1}}; for (i in occs) {print i-1,occs[i]}}'> _worker-creation-occurrences
 
