#!/bin/bash

set -e

cat scripts/run/configs-small-realistic.csv|while read -r line; do

    rno=$(echo $line|awk '{print $1}')
    clienttemplate=$(echo $line|awk '{print $2}')
    moreoptions=$(echo $line|awk '{print $1="";$2="";print $0}')
    
    echo "******************************************************"
    echo "Running experiment: rno=$rno clienttemplate=$clienttemplate moreoptions=$moreoptions"
    
    PATH=build:$PATH RDMAV_FORK_SAFE=1 nohup mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=1 -ajpc=384 -ljpc=4 -T=600 -log=logs/realistic-$rno -v=4 -warmup -satsolver=kclkclcl -pls=0 -sjd=1 -job-template=instances/job-template-priorities.json -job-desc-template=instances/selection_isc2020_394.txt -client-template=instances/$clienttemplate 2>&1 > OUT
    
    echo "Experiment done"
    echo "******************************************************"
    echo ""

done
