#!/bin/bash

# s02_extract_data.sh
# Started: Alexey Larionov, 16Oct2018
# Last updated: Alexey Larionov, 16Oct2018

# Use:
# sbatch s02_extract_data.sh

# Takes ~10-15 min to extract a one-lane data of ~80-100GB

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_extract_data
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_extract_data.log
#SBATCH --ntasks=12
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4 

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Allocated node: $(hostname)"
echo "Time: $(date)"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo "------------------ Output ------------------"
echo ""

# ---------------------------------------- #
#                    job                   #
# ---------------------------------------- #

# Stop at runtime errors
set -e

# Start message
echo "Extract source data"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare_ampliseq/analysis3/data_and_results"

source_folder="${data_folder}/s01_source_data/downloaded"
source_file="180522_K00178_0090_BHVMMTBBXX_alarionov.tar.gz"

target_folder="${data_folder}/s01_source_data/fastq"
rm -fr "${target_folder}" # remove folder if existed

# Report settings
echo "Settings:"
echo "source_folder: ${source_folder}"
echo "source_file: ${source_file}"
echo "target_folder: ${target_folder}"
echo ""

# Extract the tarball
echo "Extracting files ..."
cd "${source_folder}"
tar -xf "${source_file}"

# Move extracted files to the specified location
echo "Moving extracted files to the target folder..."
mv "${source_file%.tar.gz}" "${target_folder}"

# Completion message
echo ""
echo "Done all tasks"
date
echo ""
