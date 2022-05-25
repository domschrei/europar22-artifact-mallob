#!/bin/bash

set -e

# Find number of processes to use
if [ -z $NUM_PROCESSES ]; then
    nprocs=32
    echo "Number of processes (env. variable NUM_PROCESSES) not specified; defaulting to $nprocs processes"
else
    nprocs=$NUM_PROCESSES
    echo "Using $nprocs processes"
fi

# Find number of worker threads to run per process
if [ -z $NUM_THREADS_PER_PROCESS ]; then
    nthreadsperprocess=1
    echo "Number of worker threads per process (env. variable NUM_THREADS_PER_PROCESS) not specified; defaulting to $nthreadsperprocess threads per process"
else
    nthreadsperprocess=$NUM_THREADS_PER_PROCESS
    echo "Running $nthreadsperprocess worker threads per process"
fi

# By default, runs with non-standard "huca" option are skipped because 
# the associated effects cannot be reproduced on such a small scale.
# You can force to run them with the option "--full".
full_eval=false
if [ ! -z $1 ]; then
    if [ "$1" == "--full" ]; then
        full_eval=true
    fi
fi

# Read configuration lines from the indicated file
cat scripts/run/configs-small-realistic.csv|while read -r line; do
    
    # Parse the individual configuration options from left to right
    rno=$(echo $line|awk '{print $1}') # index of the run
    clienttemplate=$(echo $line|awk '{print $2}') # configuration file for client PEs
    # the remainder of the line is the set of additional options
    moreoptions=$(echo $line|awk '{for (i=3; i <= NF; i++) {printf("%s ", $i)}; printf("\n")}')

    # Should this run be skipped?
    if ! $full_eval && ! echo $moreoptions|grep -q "\-huca=0" && echo $moreoptions|grep -q "\-huca"; then
        echo "Skipping experiment with non-standard hops (-huca != 0)"
        echo "To run this experiment, use option \"--full\""
        continue
    fi
    
    # Check log directory to write into
    logdir="logs/realistic-$rno"
    if [ -d $logdir ]; then
        echo "Log directory $logdir already exists - skipping this experiment"
        echo "To re-run the experiment, run: rm -rf \"$logdir\""
        continue
    fi
    
    # Experiment header to STDOUT
    echo "******************************************************"
    echo "Running experiment: rno=$rno clienttemplate=$clienttemplate moreoptions=$moreoptions"
    
    # Run the experiment
    PATH=build:$PATH RDMAV_FORK_SAFE=1 mpirun -np $nprocs -map-by numa:PE=$nthreadsperprocess -bind-to core build/mallob -t=$nthreadsperprocess -q -c=1 -ajpc=384 -ljpc=4 -T=600 -log=$logdir -v=4 -warmup -satsolver=kclkclcl -pls=0 -sjd=1 -job-template=templates/job-template-priorities.json -job-desc-template=templates/selection_isc2020_384.txt -client-template=templates/$clienttemplate $moreoptions 2>&1 > OUT < /dev/null
    
    # Experiment footer to STDOUT
    echo "Experiment done"
    echo "******************************************************"
    echo ""
done
