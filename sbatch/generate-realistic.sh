#!/bin/bash

set -e

# Find number of nodes to use
if [ -z $NUM_NODES ]; then
    nodes=128
    echo "Number of nodes (env. variable NUM_NODES) not specified; defaulting to $nodes nodes"
else
    nodes=$NUM_NODES
    echo "Using $nodes nodes"
fi

# Find number of processes to run per node
if [ -z $NUM_PROCESSES_PER_NODE ]; then
    nprocspernode=12
    echo "Number of processes per node (env. variable NUM_PROCESSES_PER_NODE) not specified; defaulting to $nprocspernode processes"
else
    nprocspernode=$NUM_PROCESSES_PER_NODE
    echo "Using $nprocspernode processes per node"
fi

# Find number of worker threads to run per process
if [ -z $NUM_THREADS_PER_PROCESS ]; then
    nthreadsperprocess=4
    echo "Number of worker threads per process (env. variable NUM_THREADS_PER_PROCESS) not specified; defaulting to $nthreadsperprocess threads per process"
else
    nthreadsperprocess=$NUM_THREADS_PER_PROCESS
    echo "Running $nthreadsperprocess worker threads per process"
fi

# Instantiate sbatch files
for f in sbatch/templates/realistic-*.sh; do
    cat $f|sed 's/--nodes=.*/--nodes='$nodes'/g' \
    |sed 's/--ntasks-per-node=.*/--ntasks-per-node='$nprocspernode'/g' \
    |sed 's/--cpus-per-task=.*/--cpus-per-task='$((2*$nthreadsperprocess))'/g' \
    |sed 's/-t=[0-9]\+/-t='$nthreadsperprocess'/g' \
    > sbatch/$(basename $f)
    echo "Generated sbatch/$(basename $f)"
done


