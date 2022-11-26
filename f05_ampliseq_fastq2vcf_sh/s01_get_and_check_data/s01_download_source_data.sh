#!/bin/bash

# s01_download_source_data.sh
# Started: Alexey Larionov, 16Oct2018
# Last updated: Alexey Larionov, 16Oct2018

# Use:
# sbatch s01_download_source_data.sh

# Takes ~20-30 min for a one-lane data of ~80-100GB

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_download_source_data
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_download_source_data.log
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
echo "Download source data"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare_ampliseq/analysis3/data_and_results"

source_file="180522_K00178_0090_BHVMMTBBXX_alarionov.tar.gz"
md5_file="180522_K00178_0090_BHVMMTBBXX_alarionov.tar.gz.md5"

target_folder="${data_folder}/s01_source_data/downloaded"

# Report settings
echo "Settings:"
echo "source_file: ${source_file}"
echo "md5_file: ${md5_file}"
echo "target_folder: ${target_folder}"
echo ""

# Go to target folder
rm -fr "${target_folder}" # remove folder if existed
mkdir -p "${target_folder}"
cd "${target_folder}"

# Download files (use wget for medgen!)
echo "Downloading files:"
wget -nv --http-user=alarionov --http-password=soVeewZTIEYOkl http://sunstrider.medgen.medschl.cam.ac.uk/alarionov/"${md5_file}"
wget -nv --http-user=alarionov --http-password=soVeewZTIEYOkl http://sunstrider.medgen.medschl.cam.ac.uk/alarionov/"${source_file}"
echo ""

# Check md5 sum
echo "md5 sum check:"
md5sum -c "${md5_file}"
echo ""

# Completion message
echo "Done all tasks"
date
echo ""
