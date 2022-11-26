#!/bin/bash

# s02_check_bams_validation.sh
# Started: Alexey Larionov, 29Jun2018
# Last updated: Alexey Larionov, 14Feb2019

# Use:
# ./s02_check_bams_validation.sh &> s02_check_bams_validation.log
# or
# sbatch s03_check_bams_validation.sh

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_check_bams_validation
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_check_bams_validation.log
#SBATCH --qos=INTR
#SBATCH --ntasks=2

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
echo "Check results of BAMs validation"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
clean_bam_folder="${data_folder}/s06_clean_bam/bam"
passed_samples="${data_folder}/s06_clean_bam/passed_samples.txt"
failed_samples="${data_folder}/s06_clean_bam/failed_samples.txt"

# Progress report
echo "clean_bam_folder: ${clean_bam_folder}"
echo ""

# Make list of source bam files 
cd "${clean_bam_folder}"
clean_bam_files=$(ls *_fixmate_sort_rg.bam)

# Make list of samples 
samples=$(sed -e 's/_fixmate_sort_rg.bam//g' <<< "${clean_bam_files}")
echo "Detected $(wc -w <<< ${samples}) cleaned bam files in the folder"

# Initialise samples counters
chk=0
pass=0
fail=0

# For each sample
for sample in ${samples}
do
  
  # Get log file name
  cleanup_log="${clean_bam_folder}/${sample}_cleanup.log"
  
  # Check validation and increment pass or fail counter
  if grep -q "No errors found" "${cleanup_log}"
  then
    pass=$(( ${pass} + 1 ))
    echo "${sample}" >> "${passed_samples}"
  else
    fail=$(( ${fail} + 1 ))
    echo "${sample}" >> "${failed_samples}"
  fi
  
  chk=$(( ${chk} + 1 ))
  
  #echo -ne "Checked: ${chk}"\\r
  
done # next sample

# Print result
echo "Checked samples: ${chk}"
echo "Passed samples: ${pass}"
echo "Failed samples: ${fail}"

# Completion message
echo ""
echo "Done all tasks"
date
echo ""
