#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=1           
#SBATCH --ntasks=2           
#SBATCH --cpus-per-task=64   
#SBATCH --time=02:30:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --partition=standard
#SBATCH --account=project_465001202

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

for i in {1..10}
do
    BASE_OUTPUT_DIR="$PWD/output_1node_2task_${i}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BASE_OUTPUT_DIR

    source /users/mehrabia/build/bin/thisroot.sh

    export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

    csv_file="$BASE_OUTPUT_DIR/timing_results.csv"
    echo "Task,Dataset,Threads,Time(s)" > $csv_file

    cat << 'EOF' > $BASE_OUTPUT_DIR/worker.sh
#!/bin/bash

TASK_ID=$1
DATASET=$2
BASE_OUTPUT_DIR=$3

OUTPUT_DIR="$BASE_OUTPUT_DIR/task_$TASK_ID"
mkdir -p $OUTPUT_DIR

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

cp $DATASET/nanoaod_inputs.json $OUTPUT_DIR/
cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $OUTPUT_DIR/

cd $OUTPUT_DIR
find $DATASET/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
find $DATASET/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +
/users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $OUTPUT_DIR/output.log 2> $OUTPUT_DIR/error.log

# Extract the execution time from the output.log
elapsed_time=$(grep "Executing the computation graphs took" $OUTPUT_DIR/output.log | awk '{print $6}')
echo "$TASK_ID,$DATASET,$SLURM_CPUS_PER_TASK,$elapsed_time" >> $BASE_OUTPUT_DIR/timing_results.csv

hostname > hostname.txt
EOF

    chmod +x $BASE_OUTPUT_DIR/worker.sh

    datasets=("/scratch/project_465001202/rntuple-rc2" "/scratch/project_465001202/rntuple-rc2-cp1")

    srun --exclusive --cpus-per-task=64 -N1 -n1 bash -c "$BASE_OUTPUT_DIR/worker.sh 1 ${datasets[0]} $BASE_OUTPUT_DIR" &
    srun --exclusive --cpus-per-task=64 -N1 -n1 bash -c "$BASE_OUTPUT_DIR/worker.sh 2 ${datasets[1]} $BASE_OUTPUT_DIR" &

    wait

    echo "DONE for iteration $i."
done

