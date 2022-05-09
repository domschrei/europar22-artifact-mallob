#!/bin/bash

while read -r line; do

    npar=$(echo $line|awk '{print $1}')
    coreminperjob=$(echo $line|awk '{print $2}')
    numclients=$(echo $line|awk '{print $3}')
    activejobsperclient=$(echo $line|awk '{print $4}')
    loadedjobsperclient=$(echo $line|awk '{print $5}')
    jobtemplate=templates/job-template-sat-r3unknown_100k-${coreminperjob}coremin.json
    
    echo "******************************************************"
    echo "Running experiment: npar=$npar coreminperjob=$coreminperjob numclients=$numclients activejobsperclient=$activejobsperclient loadedjobsperclient=$loadedjobsperclient"
    
    PATH=build:$PATH RDMAV_FORK_SAFE=1 nohup mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=$numclients -ajpc=$activejobsperclient -ljpc=$loadedjobsperclient -T=320 -log=logs/uniform-$npar -v=4 -warmup -job-template=$jobtemplate
    
    echo "Experiment done"
    echo "******************************************************"
    echo ""

done < scripts/run/configs-small-uniform.csv
