#!/bin/bash

echo "******************************************************"
echo "Running experiment \"Impact of Priorities\""

PATH=build:$PATH RDMAV_FORK_SAFE=1 nohup mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=4 -ajpc=1 -jwl=60 -T=3600 -log=logs/priorities -v=4 -warmup -pls=0 -shuffle-job-descriptions -job-template=templates/job-template-priorities.json -job-desc-template=templates/selection_isc2020.txt

echo "Experiment done"
echo "******************************************************"
echo ""
