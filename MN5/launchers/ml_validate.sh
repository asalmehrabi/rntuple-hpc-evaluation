#!/bin/bash
#SBATCH --job-name=root_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=112
#SBATCH --time=02:00:00
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

# ROOT
source /home/bsc/bsc020513/root-install/bin/thisroot.sh
export ROOT_INCLUDE_PATH=/home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar:$ROOT_INCLUDE_PATH

# Virtualenv
source ~/myenv39/bin/activate

# Copiar datos y helpers
cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/nanoaod_inputs.json "$output_dir/"
cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/helpers.h "$output_dir/"
# También copia el script de validación y el JSON de referencia
cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/validate_histograms.py "$output_dir/"
cp /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/reference/histograms_reference.json "$output_dir/"

cd "$output_dir"

### generate histograms
srun --exclusive -N1 -n1 --cpus-per-task=112 python3 \
    /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/analysis.py \
    --inference --output "histograms_ml_inference.root" \
    > make_histos.log 2> make_histos.err

###validation code with validation part of analysis grand challenge
python3 /home/bsc/bsc020513/analysis-grand-challenge/analyses/cms-open-data-ttbar/validate_histograms.py \
    --histos histograms_ml_inference.root \
    --reference histograms_reference.json \
    --verbose \
    > validate.log 2> validate.err || {
      echo "‼️ Validación fallida: revisa validate.err y validate.log"
      exit 1
    }

echo "DONE. Histogramas OK y validados." 

