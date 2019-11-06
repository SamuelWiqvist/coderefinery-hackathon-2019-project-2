#!/bin/bash

nbr_threads=1
FILE=job_run_thread_parallelized_bootstrap_filter.sh

cat > $FILE << EOF
  #!/bin/sh


  # Set up for run:

  # need this since I use a LU project
  #SBATCH -A lu2019-2-19
  #SBATCH -p lu

  #SBATCH --qos=test

  # use gpu nodes
  #SBATCH -N $nbr_threads
  #SBATCH --tasks-per-node=10
  #SBATCH --exclusive

  # time consumption HH:MM:SS
  #SBATCH -t 00:05:00

  # name for script
  #SBATCH -J test_thread_parallel_bootstrap

  # controll job outputs
  #SBATCH -o lunarc_output/outputs_test_thread_parallel_bootstrap_%j.out
  #SBATCH -e lunarc_output/errors_test_thread_parallel_bootstrap_%j.err

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

  export JULIA_NUM_THREADS=$nbr_threads

  # run program

  julia /home/samwiq/'coderefinery-hackathon-2019-project-2'/non-linear-time-series-model/bootstrap_filter_thread_parallelization.jl

EOF
