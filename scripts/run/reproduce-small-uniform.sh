#!/bin/bash

set -e

# Read configuration lines from the indicated file
cat scripts/run/configs-small-uniform.csv|while read -r line; do

    # Parse the individual configuration options from left to right
    npar=$(echo $line|awk '{print $1}') # number of jobs to be processed in parallel
    coreminperjob=$(echo $line|awk '{print $2}') # CPU limit of each job in terms of core-min
    numclients=$(echo $line|awk '{print $3}') # number of PEs configured to introduce jobs
    activejobsperclient=$(echo $line|awk '{print $4}') # number of parallel jobs per client
    loadedjobsperclient=$(echo $line|awk '{print $5}') # max. number of job descriptions in memory per client
    # Job template file which describes the meta data of each job
    jobtemplate=templates/job-template-sat-r3unknown_100k-${coreminperjob}coremin.json
    
    # Check log directory to write into
    logdir="logs/uniform-$npar"
    if [ -d $logdir ]; then
        echo "Log directory $logdir already exists - skipping this experiment"
        echo "To re-run the experiment, run: rm -rf \"$logdir\""
        continue
    fi
    
    # Check whether our job template already exists
    if [ ! -f $jobtemplate ]; then
        # Create it by instantiating the generic template with the specific CPU limit
        cat templates/job-template-sat-r3unknown_100k.json|sed 's/CPUMINUTES/'$coreminperjob'/g' > $jobtemplate
    fi
    
    # Experiment header to STDOUT
    echo "******************************************************"
    echo "Running experiment: npar=$npar coreminperjob=$coreminperjob numclients=$numclients activejobsperclient=$activejobsperclient loadedjobsperclient=$loadedjobsperclient"
    
    # Run the experiment
    PATH=build:$PATH RDMAV_FORK_SAFE=1 mpirun -np 32 -map-by numa:PE=1 -bind-to core build/mallob -t=1 -q -c=$numclients -ajpc=$activejobsperclient -ljpc=$loadedjobsperclient -T=320 -log=$logdir -v=4 -warmup -job-template=$jobtemplate 2>&1 > OUT < /dev/null
    
    # Experiment footer to STDOUT
    echo "Experiment done"
    echo "******************************************************"
    echo ""
done
