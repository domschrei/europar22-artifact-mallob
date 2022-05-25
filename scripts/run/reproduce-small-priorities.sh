#!/bin/bash

set -e

# Find number of processes to use
if [ -z $NUM_PROCS ]; then
    nprocs=32
    echo "Number of processes (env. variable NUM_PROCS) not specified; defaulting to $nprocs processes"
else
    nprocs=$NUM_PROCS
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

# Check log directory to write into
logdir="logs/priorities"
if [ -d $logdir ]; then
    echo "Log directory $logdir already exists - skipping this experiment"
    echo "To re-run the experiment, run: rm -rf \"$logdir\""
    exit 0 
fi

# Experiment header to STDOUT
echo "******************************************************"
echo "Running experiment \"Impact of Priorities\""

# Run the experiment
PATH=build:$PATH RDMAV_FORK_SAFE=1 mpirun -np $nprocs -map-by numa:PE=$nthreadsperprocess -bind-to core build/mallob -t=$nthreadsperprocess -q -c=4 -ajpc=1 -jwl=60 -T=3600 -log=$logdir -v=4 -warmup -pls=0 -shuffle-job-descriptions -job-template=templates/job-template-priorities.json -job-desc-template=templates/selection_isc2020.txt 2>&1 > OUT < /dev/null

# Experiment footer to STDOUT
echo "Experiment done"
echo "******************************************************"
echo ""
