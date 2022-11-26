#!/bin/bash

# s02_check_gvcf_logs.sh
# Started: Alexey Larionov, 24Jul2018
# Last updated: Alexey Larionov, 25Feb2019

# Use:
# sbatch s02_check_gvcf_logs.sh

# This script checks the HC log files for phrase "".HaplotypeCaller done. Elapsed time:"
# Counts and makes reports with names of passed and failed samples

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_check_gvcf_logs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_check_gvcf_logs.log
#SBATCH --ntasks=1
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
echo "Check log files after making g.vcf-s"
date
echo ""

# Files and folders

scripts_folder="$( pwd -P )"

passed_samples="${scripts_folder}/s02_passed_samples.txt"
failed_samples="${scripts_folder}/s02_failed_samples.txt"
> "${passed_samples}"
> "${failed_samples}"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
bam_folder="${data_folder}/s08_preprocessed_bam/idrl_bqsr_bam"
gvcf_folder="${data_folder}/s09_raw_vcf/gvcf"

# Progress report
echo "--- Folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo "bam_folder: ${bam_folder}"
echo "gvcf_folder: ${gvcf_folder}"
echo "passed_samples: ${passed_samples}"
echo "failed_samples: ${failed_samples}"
echo ""

# Count source bam files
cd "${bam_folder}"
bam_files=$(ls *_fixmate_sort_rg_idrl_bqsr.bam)
bam_samples=$(sed -e 's/_fixmate_sort_rg_idrl_bqsr.bam//g' <<< "${bam_files}")
echo "Detected $(wc -w <<< ${bam_samples}) bam files in the source folder"

# Count resultant g.vcf files
cd "${gvcf_folder}"
gvcf_files=$(ls *.g.vcf.gz)
gvcf_samples=$(sed -e 's/.g.vcf.gz//g' <<< "${gvcf_files}")
echo "Detected $(wc -w <<< ${gvcf_samples}) g.vcf files in the output folder"

# Count log files to check
log_files=$(ls *.log)
log_samples=$(sed -e 's/.log//g' <<< "${log_files}")
echo "Detected $(wc -w <<< ${log_samples}) log files in the output folder"
echo ""

# --- Check what samples successfully completed --- #

# Because of parallel execution ( &-loop ) the failed HC runs will not
# be picked by set -e.  There were some random failures in fale system I/O
# on cluster during this analysis. So, I had to verufy the completion of
# each sample

# Initialise samples counters
chk=0
pass=0
fail=0

# For each log file
for sample in ${log_samples}
do

  # Get log file name
  gvcf_log="${gvcf_folder}/${sample}.log"

  # Check if HC has completed successfully
  if grep -q "ProgressMeter -            done" "${gvcf_log}"
  then
    pass=$(( ${pass} + 1 ))
    echo "${sample}" >> "${passed_samples}"
  else
    fail=$(( ${fail} + 1 ))
    echo "${sample}" >> "${failed_samples}"
  fi

  chk=$(( ${chk} + 1 ))

done # next sample

# Print result
echo "Within the detected log files:"
echo "Passed samples: ${pass}"
echo "Failed samples: ${fail}"
echo ""

# Completion message
echo "Done all tasks"
date
echo ""
