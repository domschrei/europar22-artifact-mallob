#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "First argument is not a valid directory."
    exit 1
fi

files_init=""
files_tree=""
files_bala=""
legends=""
for d in $@ ; do
    # Append to plot files and legend labels
    files_init="$files_init $d/init-latencies-histogram-normalized"
    files_tree="$files_tree $d/treegrowth-latencies-histogram-normalized"
    files_bala="$files_bala $d/balancing-latencies-histogram-normalized"
    legends="$legends -l=$d"
done

# Plot latencies
python3 scripts/plot/plot_curves.py $files_init $legends \
-nomarkers -xy -ymin=-0.001 -xlabel="Init. scheduling latency [s]" -ylabel="Density"
python3 scripts/plot/plot_curves.py $files_tree $legends \
-nomarkers -xy -ymin=-0.001 -xlabel="Tree growth latency [s]" -ylabel="Density"
python3 scripts/plot/plot_curves.py $files_bala $legends \
-nomarkers -xy -ymin=-0.001 -xlabel="Balancing latency [s]" -ylabel="Density"
