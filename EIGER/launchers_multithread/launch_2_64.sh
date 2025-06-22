#!/bin/bash -l
#SBATCH --job-name=root_test_2
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=64
#SBATCH --time=08:00:00
#SBATCH --partition=normal  
#SBATCH --account=g166  
#SBATCH --mem=256G 
#SBATCH --output=out/output_2_%j.log
#SBATCH --error=out/error_2_%j.err

base_output_dir="$PWD/performance_output_2_$(date +%Y%m%d_%H%M%S)"
mkdir -p $base_output_dir

csv_file="$base_output_dir/performance_results.csv"
echo "nodes,tasks,cpus-per-task,exec_time" > $csv_file

module load cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python

source /users/amehrabi/build/bin/thisroot.sh
export ROOT_INCLUDE_PATH=/users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH
source /users/amehrabi/AGC-venv/bin/activate

output_dir="$base_output_dir/1nodes_2tasks_64cpus"
mkdir -p $output_dir

cp /users/amehrabi/nanoaod_inputs.json $output_dir/
cp /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

srun --ntasks=2 --cpus-per-task=64 bash -c "
    cd $output_dir;
    find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/fadvise -a dontneed {} \;
    find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/mincore {} +;
    /usr/bin/time -v /users/amehrabi/AGC-venv/bin/python3 /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py --ncores 64 > $output_dir/output.log 2> $output_dir/error.log
"

exec_time=$(grep "Executing the computation graphs took" $output_dir/output.log | awk '{print $6}')

echo "1,2,64,$exec_time" >> $csv_file

echo "DONE."

