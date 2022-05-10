#!/bin/bash

set -e

cat scripts/run/configs-small-realistic.csv|while read -r line; do

    rno=$(echo $line|awk '{print $1}')
    clienttemplate=$(echo $line|awk '{print $2}')
    moreoptions=$(echo $line|awk '{for (i=3; i <= NF; i++) {printf("%s ", $i)}; printf("\n")}')

    logdir="logs/realistic-$rno"
    if [ -d $logdir ]; then
        echo "Log directory $logdir already exists - skipping this experiment"
        echo "To re-run the experiment, run: rm -rf \"$logdir\""
        continue
    fi
    
    echo "******************************************************"
    echo "Running experiment: rno=$rno clienttemplate=$clienttemplate moreoptions=$moreoptions"
    
    PATH=build:$PATH RDMAV_FORK_SAFE=1 mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=1 -ajpc=384 -ljpc=4 -T=600 -log=$logdir -v=4 -warmup -satsolver=kclkclcl -pls=0 -sjd=1 -job-template=templates/job-template-priorities.json -job-desc-template=templates/selection_isc2020_384.txt -client-template=templates/$clienttemplate $moreoptions 2>&1 > OUT < /dev/null
    
    echo "Experiment done"
    echo "******************************************************"
    echo ""

done
