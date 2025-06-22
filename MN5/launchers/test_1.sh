#!/bin/bash

#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=80
#SBATCH --time=00:30:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --account=bsc20
#SBATCH --partition=standard
#SBATCH --qos=gp_debug  

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
output_dir="$PWD/output_test_srun_$TIMESTAMP"
mkdir -p "$output_dir"
module load python/3.9.16

source /home/bsc/bsc020513/root-install/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH
source ~/myenv39/bin/activate

python3 /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py \
    > "$output_dir/output.log" 2> "$output_dir/error.log"

echo "DONE."

