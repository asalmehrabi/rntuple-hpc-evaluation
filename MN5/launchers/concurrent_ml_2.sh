#!/bin/bash
#SBATCH --job-name=ml_concurrent
#SBATCH --nodes=2
#SBATCH --ntasks=4  # number of concurrent jobs 
#SBATCH --cpus-per-task=56
#SBATCH --time=02:00:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --account=bsc20
##SBATCH --partition=standard
#SBATCH --qos=gp_bscls

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


for i in $(seq 1 4); do
  srun --exclusive -N1 -n1 --cpus-per-task=56 \
    python3 /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py \
    --inference --output "output_$i.root" > "output_$i.log" 2> "error_$i.log" &
done

wait
echo "DONE."

