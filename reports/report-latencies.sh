#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "First argument is not a valid directory."
    exit 1
fi

for d in $@ ; do

    # Extract program options from logs of rank zero
    options=$(cd "$d" && cat 0/log.0|head -10|grep "Program options")
    # Extract number of clients from the program options
    numclients=$(echo $options|grep -oE " -c=[0-9]+ "|grep -oE "[0-9]+")
    # Find out which is the highest process rank
    lastclient=$(cd "$d" && echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
    # Calculate the rank of the first client 
    firstclient=$(($lastclient - $numclients + 1))
    # Extract "hops" option
    huca=$(echo $options|grep -oE " -huca=[0-9-]+ "|grep -oE "[0-9-]+")
    
    # Sort balancing and treegrowth latencies
    for l in balancing treegrowth; do 
        cat $d/*/*${l}*|sort -g > $d/${l}-latencies 
    done
    # Extract initial scheduling latencies
    > $d/init-latencies
    for i in $(seq $firstclient $lastclient); do
        cat $d/$i/*|grep Scheduling|grep -oE "latency:.*"|grep -oE "[0-9\.]+" >> $d/init-latencies
    done
    LC_ALL=C sort -s -g $d/init-latencies -o $d/init-latencies
    
    # Generate histograms
    for f in $d/*-latencies ; do
        cat "$f"|awk '{printf("%.3f\n", $1)}'|awk '{h[$1] += 1} END {for (t in h) {print t,h[t]}}'\
        |LC_ALL=C sort -g > ${f}-histogram
    done
    
    # Normalize histograms
    for f in $d/*-latencies-histogram ; do 
        sum=$(cat $f|awk '{s+=$2} END {print s}')
        cat $f|awk '{print $1,$2/'$sum'}' > $f-normalized
    done
done

# Plot latencies
reports/plot-latencies.sh $@
