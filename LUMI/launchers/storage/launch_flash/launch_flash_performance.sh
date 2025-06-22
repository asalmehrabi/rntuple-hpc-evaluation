#!/bin/bash

#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --time=02:00:00
#SBATCH --partition=standard
#SBATCH --account=project_465001202
#SBATCH --mem=192G

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

base_output_dir="$PWD/flash_dir/performance_output_flash$(date +%Y%m%d_%H%M%S)"
mkdir -p $base_output_dir

csv_file="$base_output_dir/performance_results.csv"
echo "cores,build_time_run1,exec_time_run1,build_time_run2,exec_time_run2" > $csv_file

for cores in 128 64 32 16; do
    output_dir="$base_output_dir/${cores}_cores"
    mkdir -p $output_dir

    cp /flash/project_465001202/rntuple-rc2/nanoaod_inputs.json $output_dir/
    cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

    cd $output_dir

    export SLURM_CPUS_PER_TASK=$cores

    results=""

    for run in 1 2; do
	find /flash/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
	find /flash/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +
        /users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py --ncores $cores > $output_dir/output_run${run}.log 2> $output_dir/error_run${run}.log

        build_time=$(grep "Building the computation graphs took" $output_dir/output_run${run}.log | awk '{print $6}')
        exec_time=$(grep "Executing the computation graphs took" $output_dir/output_run${run}.log | awk '{print $6}')

        results="${results},${build_time},${exec_time}"
    done

    echo "$cores${results}" >> $csv_file
done
