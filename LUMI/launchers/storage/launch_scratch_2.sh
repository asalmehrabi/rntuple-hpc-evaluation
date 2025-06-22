#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=02:30:00  
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --partition=standard
#SBATCH --account=project_465001202

BASE_OUTPUT_DIR="$PWD/performance_output_scratch_10runs_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BASE_OUTPUT_DIR

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

# Crear un archivo CSV para guardar los tiempos de ejecución
csv_file="$BASE_OUTPUT_DIR/performance_results.csv"
echo "cores,exec_time_run1,exec_time_run2,exec_time_run3,exec_time_run4,exec_time_run5,exec_time_run6,exec_time_run7,exec_time_run8,exec_time_run9,exec_time_run10" > $csv_file

for cores in 128 64 32 16; do
    output_dir="$BASE_OUTPUT_DIR/${cores}_cores"
    mkdir -p $output_dir

    cp /scratch/project_465001202/rntuple-rc2/nanoaod_inputs.json $output_dir/
    cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

    results="$cores"

    for run in {1..3}; do
        srun --exclusive -N1 -n1 --cpus-per-task=$cores bash -c "
            cd $output_dir;
            find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
            find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +;
            /usr/bin/time -v /users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py --ncores $cores > $output_dir/output_run${run}.log 2> $output_dir/error_run${run}.log
        "

        exec_time=$(grep "Executing the computation graphs took" $output_dir/output_run${run}.log | awk '{print $6}')

        results="${results},${exec_time}"
    done

    echo "$cores${results}" >> $csv_file
done

echo "DONE."

