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
cd "$calldir"

# Extract all load events
cat "$basedir"/*/log.*|grep -oE "[0-9\.]+ [0-9]+ LOAD [01]"|LC_ALL=C sort -g -s > _load_events
# Convert load events into a time series of system utilization
cat _load_events|awk '\
/LOAD 1/ {load+=1}\
/LOAD 0/ {load-=1}\
/LOAD/ {print $1,load}' > _loads
# Calculate sliding averages of the utilization at different window sizes
for window in 1 15 60; do
    python3 scripts/eval/sliding_average.py _loads $window | \
    awk '{print $1,$2/'$(($lastclient+1))'}' > _loads_slavg_${window}s
done

# Plot utilization
python3 scripts/plot/plot_curves.py -xy _loads_slavg_{1,15,60}s -nomarkers -linestyles='-' \
-linewidths=0.1,0.6,1 -colors="#ffe0c0,#ffb070,#ff7f00" -nolegend \
-ymin=0.9 -ymax=1 -xlabel="Elapsed time [s]" -ylabel="Utilization"

#cat */log.*|grep "LOAD 1"|sed 's/[()+#-]//g'|sed 's/:/ /g'|awk '{cs[$5][$6]+=1} END {for (j in cs) {for (i in cs[j]) {occs[cs[j][i]]+=1}}; for (i in occs) {print i-1,occs[i]}}'> _worker-creation-occurrences
