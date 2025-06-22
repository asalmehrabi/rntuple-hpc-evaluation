#!/bin/bash
#SBATCH --job-name=my_python_job        # Name of the job
#SBATCH --output=my_python_job_output.txt   # File for standard output
#SBATCH --error=my_python_job_error.txt     # File for standard error
#SBATCH --time=02:00:00                 # Max wall time (HH:MM:SS)
#SBATCH --nodes=4                      # Number of nodes
#SBATCH --ntasks-per-node=1            # Number of tasks per node
#SBATCH --cpus-per-task=112            # Number of CPUs per task
##SBATCH --mem=64G                     # Total memory per node
#SBATCH --account=bsc20                # Account for billing
#SBATCH --qos=gp_bsccs                 # Quality of Service

# Load the appropriate Python module
module load python/3.12.1

# Activate virtual environment if needed
# source /path/to/your/venv/bin/activate

# Run the Python script with alpha as an argument
python3 graph.py --alpha 0.0001

