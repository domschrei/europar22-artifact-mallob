#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

cd "$basedir"

# Extract program options from logs of rank zero
options=$(cat 0/log.0|head -10|grep "Program options")
# Extract number of clients from the program options
numclients=$(echo $options|grep -oE " -c=[0-9]+ "|grep -oE "[0-9]+")
# Extract number of active jobs per client from the program options
ajpc=$(echo $options|grep -oE " -ajpc=[0-9]+ "|grep -oE "[0-9]+")
# Find out which is the highest process rank
lastclient=$(echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
# Calculate the rank of the first client 
# (which is the one to output aggregated information)
firstclient=$(($lastclient - $numclients + 1))
# Calculate the number of parallel jobs
npar=$(($numclients * $ajpc))

echo "1st client directory: $firstclient"

# Extract the required warmup time until Mallob was set up to take jobs
warmuptime=$(cat "$firstclient"/log.*|grep "I am worker"|head -1|awk '{print $1}')

echo "Warmup time: $warmuptime"s

# Compute the maximum throughput measured:
# We filter lines which report the number of jobs processed 
# and use the lines' timestamps to compute the throughput.
maxthroughput=$(cat "$firstclient"/log.*|grep "processed="|sed 's/[a-z]\+=//g'|\
awk 'BEGIN {max=0} {tp=$7/($1-'$warmuptime'); max=tp>max?tp:max} END {print max}')

echo "Max. throughput: $maxthroughput jobs/sec"

# Compute the throughput of a hypothetical optimal rigid scheduler (add leading zero)
optthroughput=$(echo "$npar*3.2/60"|bc -l|sed -e 's/^-\./-0./' -e 's/^\./0./')

echo "Opt. throughput: $optthroughput jobs/sec"
echo "Througput efficiency: $(echo "$maxthroughput/$optthroughput"|bc -l)"

# Compute the average measured CPU utilization of worker threads:
# Extract all measured cpu ratios from the subprocess log files,
# cap each ratio at 100%, and calculate the average.
cpuratio=$(cat */subproc.*|grep cpuratio|grep -v child_main|grep -oE "cpuratio=[0-9\.]+"|\
grep -oE "[0-9\.]+"|awk '{r=$1>1?1:$1; s+=r; c+=1} END {print s/c}')

echo "Mean measured CPU utilization of worker threads: $cpuratio"
