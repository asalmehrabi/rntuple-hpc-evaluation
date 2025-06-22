#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128 
#SBATCH --time=02:30:00  # Incrementar el tiempo total para cubrir las 5 ejecuciones
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --partition=standard
#SBATCH --account=project_465001202

base_output_dir="$PWD/output_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p $base_output_dir

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

csv_file="$base_output_dir/timing_results.csv"
echo "Run,Threads,Time(s)" > $csv_file

for run in {1..5}; do
    output_dir="$base_output_dir/run_$run"
    mkdir -p $output_dir

    cp /scratch/project_465001202/rntuple-rc2/nanoaod_inputs.json $output_dir/
    cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

    cd $output_dir

    find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
    find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +
    /users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $output_dir/output.log 2> $output_dir/error.log

    elapsed_time=$(grep "Executing the computation graphs took" $output_dir/output.log | awk '{print $6}')

    echo "$run,128,$elapsed_time" >> $csv_file

    cd $base_output_dir
done

echo "DONE."

