#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

# Find out which is the highest process rank
calldir="$(pwd)"
cd "$basedir"
lastclient=$(echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
echo $lastclient+1 PEs
mkdir -p data
cd "$calldir"

# Extract all load events
cat "$basedir"/*/log.*|grep -oE "[0-9\.]+ [0-9]+ LOAD [01]"|LC_ALL=C sort -g -s > ${basedir}/data/load_events
# Convert load events into a time series of system utilization
cat ${basedir}/data/load_events|awk '\
/LOAD 1/ {load+=1}\
/LOAD 0/ {load-=1}\
/LOAD/ {print $1,load}' > ${basedir}/data/loads
# Calculate sliding averages of the utilization at different window sizes
for window in 1 15 60; do
    python3 scripts/eval/sliding_average.py ${basedir}/data/loads $window | \
    awk '{print $1,$2/'$(($lastclient+1))'}' > ${basedir}/data/loads_slavg_${window}s
done

# Plot utilization
report/plot-utilization.sh $@
