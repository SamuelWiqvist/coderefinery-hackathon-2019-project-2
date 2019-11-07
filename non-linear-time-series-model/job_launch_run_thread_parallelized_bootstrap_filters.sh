#!/bin/bash

# This script creates the run-scripts for the 4 runs with different number of threads

# set number of threads
nbr_threads1=1
nbr_threads2=4
nbr_threads3=12
nbr_threads4=15

# set FILE names
FILE1="job_run_thread_parallelized_bootstrap_filter_${nbr_threads1}.sh"
FILE2="job_run_thread_parallelized_bootstrap_filter_${nbr_threads2}.sh"
FILE3="job_run_thread_parallelized_bootstrap_filter_${nbr_threads3}.sh"
FILE4="job_run_thread_parallelized_bootstrap_filter_${nbr_threads4}.sh"

# arrays with file names and nbr of threads
FILES=($FILE1 $FILE2 $FILE3 $FILE4)
threads=($nbr_threads1 $nbr_threads2 $nbr_threads3 $nbr_threads4)

# loop over each file and thread
for ((i=0;i<=$((${#FILES[@]} - 1));i++)); do

# check if file exists, if not create an empty file
if [ ! -e ${FILES[$i]} ]; then
  echo >> ${FILES[$i]}
fi

outputfile="lunarc_output/outputs_test_thread_parallel_bootstrap_${threads[$i]}_%j.out"
errorfile="lunarc_output/errors_test_thread_parallel_bootstrap_${threads[$i]}_%j.err"


# cat the run script info into the run file
cat > ${FILES[$i]} << EOF
#!/bin/sh

# need this since I use a LU project
#SBATCH -A lu2019-2-19
#SBATCH -p lu

# for priority
#SBATCH --qos=test

#SBATCH -N 1
#SBATCH --tasks-per-node=${threads[$i]}
#SBATCH --exclusive

# time consumption HH:MM:SS
#SBATCH -t 00:05:00

# name for script
#SBATCH -J test_thread_parallel_bootstrap

# controll job outputs
#SBATCH -o $outputfile
#SBATCH -e $errorfile

# notification
#SBATCH --mail-user=samuel.wiqvist@matstat.lu.se
#SBATCH --mail-type=ALL

# load modules
ml load GCC/6.4.0-2.28
ml load OpenMPI/2.1.2
ml load julia/1.0.0

# set correct path
pwd
cd ..
pwd

export JULIA_NUM_THREADS=${threads[$i]}

# run program
julia /home/samwiq/'coderefinery-hackathon-2019-project-2'/non-linear-time-series-model/bootstrap_filter_thread_parallelization.jl
EOF


# run job
sbatch ${FILES[$i]}


done
