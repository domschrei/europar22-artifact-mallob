#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

python3 scripts/plot/plot_curves.py -xy \
${basedir}/data/{volume,time}_per_prio -y2 -xlabel='Priority $p_j$' \
-ylabel='Mean assigned volume $v_j$' -y2label='Mean response time [s]' -ymin=0 -y2min=0 \
-nolegend -xsize=2.8 -ysize=2.3
