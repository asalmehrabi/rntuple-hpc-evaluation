#!/bin/bash -l

#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=08:00:00
#SBATCH --partition=normal  
#SBATCH --account=g166  
#SBATCH --mem=256G 
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/output_%j.err

base_output_dir="$PWD/performance_output_$(date +%Y%m%d_%H%M%S)"
mkdir -p $base_output_dir

csv_file="$base_output_dir/performance_results.csv"
echo "cores,build_time,exec_time" > $csv_file

module load cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python

source /users/amehrabi/build/bin/thisroot.sh
export ROOT_INCLUDE_PATH=/users/amehrabi/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

source /users/amehrabi/AGC-venv/bin/activate

for cores in 16 32 64 128; do
    output_dir="$base_output_dir/${cores}_cores"
    mkdir -p $output_dir

    export SLURM_CPUS_PER_TASK=$cores

    cp /users/amehrabi/nanoaod_inputs.json  $output_dir/
    cp /users/amehrabi/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

    cd $output_dir

    /users/amehrabi/AGC-venv/bin/python3 /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $output_dir/output.log 2> $output_dir/error.log

    build_time=$(grep "Building the computation graphs took" $output_dir/output.log | awk '{print $6}')
    exec_time=$(grep "Executing the computation graphs took" $output_dir/output.log | awk '{print $6}')

    echo "$cores,$build_time,$exec_time" >> $csv_file
done

