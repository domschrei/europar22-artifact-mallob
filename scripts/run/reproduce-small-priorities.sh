#!/bin/bash

set -e

logdir="logs/priorities"
if [ -d $logdir ]; then
    echo "Log directory $logdir already exists - skipping this experiment"
    echo "To re-run the experiment, run: rm -rf \"$logdir\""
    continue
fi

echo "******************************************************"
echo "Running experiment \"Impact of Priorities\""

PATH=build:$PATH RDMAV_FORK_SAFE=1 mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=4 -ajpc=1 -jwl=60 -T=3600 -log=$logdir -v=4 -warmup -pls=0 -shuffle-job-descriptions -job-template=templates/job-template-priorities.json -job-desc-template=templates/selection_isc2020.txt 2>&1 > OUT < /dev/null

echo "Experiment done"
echo "******************************************************"
echo ""
