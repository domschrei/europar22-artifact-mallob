#!/bin/bash
#SBATCH --nodes=128
#SBATCH --ntasks-per-node=12
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-core=2
#SBATCH -t 01:10:00
#SBATCH -p general # general or micro 
#SBATCH --account=PROJID
#SBATCH -J mallob_experiment
#SBATCH --ear=off # Turn off Energe-Aware Runtime (which may tamper with clock rates)

# SBATCH --ear-mpi-dist=openmpi # Switch this on to use OpenMPI (we do not)

# SuperMUC has TWO processors with 24 physical cores each, totalling 48 physical cores (96 hwthreads).
# See: https://doku.lrz.de/download/attachments/43321076/SuperMUC-NG_computenode.png

# Load the same modules to build Mallob
module load slurm_setup
module unload devEnv/Intel/2019 intel-mpi
module load gcc/9 intel-mpi/2019-gcc cmake/3.14.5 gdb/9.1

# For debugging: List all modules, which mpirun is used, and how many ranks are involved.
module list
which mpirun
echo "#ranks: $SLURM_NTASKS"

# Default logging destination: HOME directory
logdir=logs/mallob_chaos_doublejobs_$SLURM_JOB_ID
# If available, log to WORK directory which is faster
if [ -d $WORK_PROJID ]; then logdir="$WORK_PROJID/$logdir"; fi

# Base Mallob command
cmd="build/mallob -q -c=4 -ajpc=384 -ljpc=4 -T=3600 -t=4 -log=$logdir -v=4 -warmup -satsolver=kclkclcl -pls=0 -job-template=instances/job-template-priorities.json -job-desc-template=instances/sat2020 -client-template=instances/client-template-doublejobs.json -sjd=1 -ba=8 -huca=0"

# Pre-create log directory and subdirectories for each rank:
# This is much more efficient than letting each rank try and 
# create a directory at the same time (which may take minutes 
# in bad cases!)
mkdir -p "$logdir"
oldpath=$(pwd)
cd "$logdir"
for rank in $(seq 0 $(($SLURM_NTASKS-1))); do mkdir $rank; done
cd "$oldpath"

# Export two important environment variables to properly execute solver subprocesses
export PATH="build/:$PATH"
export RDMAV_FORK_SAFE=1

# Launch the actual job
echo JOB_LAUNCHING
echo "$cmd"
PATH="build/:$PATH" RDMAV_FORK_SAFE=1 srun -n $SLURM_NTASKS $cmd
echo JOB_FINISHED
