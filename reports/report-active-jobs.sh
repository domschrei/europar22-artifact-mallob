#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "First argument is not a valid directory."
    exit 1
fi

calldir="$(pwd)"

# Iterate over all provided directories (and assemble the plot command)
count=0
files=""
legends=""
for basedir in $@; do
    count=$((count+1))
    cd "$basedir"
    # Extract number of active jobs over time
    cat 0/log.*|grep -E "sysstate.*jobs="|sed 's/jobs=//g'|awk '{print $1,$6}' > "${calldir}/_a_j_$count"
    files="$files ${calldir}/_a_j_$count"
    legends="$legends -l=$(basename "$basedir")"
    cd "$calldir"
done

# Plot the graph of active jobs over time
python3 scripts/plot/plot_curves.py -xy \
$files $(echo $legends|sed 's/_/-/g') -linestyles=- \
-xlabel="Elapsed time [s]" -ylabel="Active jobs" -nomarkers -lw=1.0
