#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

# Plot utilization
python3 scripts/plot/plot_curves.py -xy ${basedir}/data/loads_slavg_{1,15,60}s -nomarkers -linestyles='-' \
-linewidths=0.1,0.6,1 -colors="#ffe0c0,#ffb070,#ff7f00" -nolegend \
-ymin=0.9 -ymax=1 -xlabel="Elapsed time [s]" -ylabel="Utilization"
