#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "First argument is not a valid directory."
    exit 1
fi

calldir="$(pwd)"

# Iterate over all provided directories (and assemble the plot command)
for basedir in $@; do
    cd "$basedir"
    mkdir -p data
    # Extract number of active jobs over time
    cat 0/log.*|grep -E "sysstate.*jobs="|sed 's/jobs=//g'|awk '{print $1,$6}' > data/active_jobs
    cd "$calldir"
done

report/plot-active-jobs.sh $@
