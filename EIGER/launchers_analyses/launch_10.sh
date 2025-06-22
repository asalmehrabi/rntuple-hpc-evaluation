#!/bin/bash -l

#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=08:00:00
#SBATCH --partition=normal  
#SBATCH --account=g166  
#SBATCH --mem=256G 
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err

base_output_dir="$PWD/performance_output_10runs$(date +%Y%m%d_%H%M%S)"
mkdir -p $base_output_dir

csv_file="$base_output_dir/performance_results.csv"
echo "cores,exec_time_run1,exec_time_run2,exec_time_run3,exec_time_run4,exec_time_run5,exec_time_run6,exec_time_run7,exec_time_run8,exec_time_run9,exec_time_run10" > $csv_file

module load cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python

source /users/amehrabi/build/bin/thisroot.sh
export ROOT_INCLUDE_PATH=/users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

source /users/amehrabi/AGC-venv/bin/activate

for cores in 128 64 32 16; do
    output_dir="$base_output_dir/${cores}_cores"
    mkdir -p $output_dir

    cp /users/amehrabi/nanoaod_inputs.json $output_dir/
    cp /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

    results="$cores"

    for run in {1..10}; do
        srun --cpus-per-task=$cores bash -c "
            cd $output_dir;
            find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/fadvise -a dontneed {} \;
            find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/mincore {} +;
            /usr/bin/time -v /users/amehrabi/AGC-venv/bin/python3 /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py --ncores $cores > $output_dir/output_run${run}.log 2> $output_dir/error_run${run}.log
        "

        exec_time=$(grep "Executing the computation graphs took" $output_dir/output_run${run}.log | awk '{print $6}')

        results="${results},${exec_time}"
    done

    echo "$cores${results}" >> $csv_file
done

echo "DONE".
