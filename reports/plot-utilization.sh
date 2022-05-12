#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "No valid directory provided."
    exit 1
fi

for d in $@; do
    # Plot utilization
    python3 scripts/plot/plot_curves.py -xy \
    ${d}/data/loads_slavg_{1,15,60}s -nomarkers -linestyles='-' \
    -linewidths=0.2,0.7,1 -colors="#ffd0b0,#ffb070,#ff7f00" -nolegend \
    -ymax=1 -xlabel="Elapsed time [s]" -ylabel="Utilization"
done
