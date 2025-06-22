#!/bin/bash -l

#SBATCH --job-name=root_test
#SBATCH --nodes=8           
#SBATCH --ntasks=8         
#SBATCH --cpus-per-task=128   
#SBATCH --time=02:30:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --partition=normal
#SBATCH --account=g166
#SBATCH --mem=256G
#SBATCH -C mc
BASE_OUTPUT_DIR="$PWD/output_8node_8task$(date +%Y%m%d_%H%M%S)"
mkdir -p $BASE_OUTPUT_DIR

module load cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1

source /users/amehrabi/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

csv_file="$BASE_OUTPUT_DIR/timing_results.csv"
echo "Run,Threads,Time(s)" > $csv_file

cat << 'EOF' > $BASE_OUTPUT_DIR/worker.sh
#!/bin/bash

TASK_ID=$1
BASE_OUTPUT_DIR=$2

OUTPUT_DIR="$BASE_OUTPUT_DIR/task_$TASK_ID"
mkdir -p $OUTPUT_DIR

module load cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1

source /users/amehrabi/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

cp /users/amehrabi/nanoaod_inputs.json $OUTPUT_DIR/
cp /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $OUTPUT_DIR/

cd $OUTPUT_DIR
find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/fadvise -a dontneed {} \;
find /project/g166/rntuple-rc2/nanoAOD/ -type f -exec /project/g166/mincore {} +
/users/amehrabi/AGC-venv/bin/python3 /users/amehrabi/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $OUTPUT_DIR/output.log 2> $OUTPUT_DIR/error.log

# Extract the execution time from the output.log
elapsed_time=$(grep "Executing the computation graphs took" $OUTPUT_DIR/output.log | awk '{print $6}')
echo "$TASK_ID,$SLURM_CPUS_PER_TASK,$elapsed_time" >> $BASE_OUTPUT_DIR/timing_results.csv

hostname > hostname.txt
EOF

chmod +x $BASE_OUTPUT_DIR/worker.sh

for j in $(seq 1 $SLURM_NTASKS); do
    srun --exclusive -N1 -n1 --cpus-per-task=128 $BASE_OUTPUT_DIR/worker.sh $j $BASE_OUTPUT_DIR &
done

wait

echo "DONE."

