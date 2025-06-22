#!/bin/bash

#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=14
#SBATCH --time=00:30:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --account=bsc20
#SBATCH --partition=standard
#SBATCH --qos=gp_debug

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
output_dir="$PWD/output_test_srun_$TIMESTAMP"
mkdir -p "$output_dir"

module load gcc
module load python/3.9.16

source /home/bsc/bsc020513/root-install/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

source ~/myenv39/bin/activate

cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/nanoaod_inputs.json "$output_dir/"
cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h "$output_dir/"

cd "$output_dir"

srun --exclusive -N1 -n1 --cpus-per-task=14 python3 /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py \
    > output.log 2> error.log

echo "DONE."

