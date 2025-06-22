#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=2            
#SBATCH --ntasks=2           
#SBATCH --cpus-per-task=128  
#SBATCH --time=02:30:00
#SBATCH --output=output_%j.log
#SBATCH --error=error_%j.err
#SBATCH --partition=standard
#SBATCH --account=project_465001202

BASE_OUTPUT_DIR="$PWD/output_multithreaded_2nodes$(date +%Y%m%d_%H%M%S)"
mkdir -p $BASE_OUTPUT_DIR

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

csv_file="$BASE_OUTPUT_DIR/timing_results.csv"
echo "Run,Threads,Time(s)" > $csv_file

cat << 'EOF' > $BASE_OUTPUT_DIR/worker.sh
#!/bin/bash

TASK_ID=$1
BASE_OUTPUT_DIR=$2

OUTPUT_DIR="$BASE_OUTPUT_DIR/task_$TASK_ID"
mkdir -p $OUTPUT_DIR

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

cp /scratch/project_465001202/rntuple-rc2/nanoaod_inputs.json $OUTPUT_DIR/
cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $OUTPUT_DIR/

cd $OUTPUT_DIR
find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +
/users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $OUTPUT_DIR/output.log 2> $OUTPUT_DIR/error.log

elapsed_time=$(grep "Executing the computation graphs took" $OUTPUT_DIR/output.log | awk '{print $6}')
echo "$TASK_ID,128,$elapsed_time" >> $BASE_OUTPUT_DIR/timing_results.csv

hostname > hostname.txt
EOF

chmod +x $BASE_OUTPUT_DIR/worker.sh

for j in $(seq 1 2); do
    srun --exclusive -N1 -n1 $BASE_OUTPUT_DIR/worker.sh $j $BASE_OUTPUT_DIR &
done

wait

echo "DONE."

