#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128 
#SBATCH --time=00:30:00
#SBATCH --output=out/output_%j.log
#SBATCH --error=out/error_%j.err
#SBATCH --partition=standard
#SBATCH --account=project_465001202

output_dir="$PWD/output_test_srun$(date +%Y%m%d_%H%M%S)"
mkdir -p $output_dir

module load PrgEnv-cray
module switch PrgEnv-cray PrgEnv-gnu
module load cray-python/3.9.12.1
module load LUMI/22.08 lumi-container-wrapper

source /users/mehrabia/build/bin/thisroot.sh

export ROOT_INCLUDE_PATH=/users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

cp /scratch/project_465001202/rntuple-rc2/nanoaod_inputs.json $output_dir/
cp /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h $output_dir/

cd $output_dir

find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/fadvise -a dontneed {} \;
find /scratch/project_465001202/rntuple-rc2/nanoAOD/ -type f -exec /project/project_465001202/mincore {} +

srun --exclusive -N1 -n1 --cpus-per-task=128 /users/mehrabia/AGC-venv/bin/python3 /users/mehrabia/AGC/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py > $output_dir/output.log 2> $output_dir/error.log

echo "DONE."

