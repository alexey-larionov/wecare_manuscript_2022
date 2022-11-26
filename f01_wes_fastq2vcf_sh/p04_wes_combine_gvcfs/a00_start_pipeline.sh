#!/bin/bash

# a00_start_pipeline.sh
# Start combining gvcfs
# Alexey Larionov, 23Aug2016

## Read parameter
job_file="${1}"
scripts_folder="${2}"

# Read job's settings
source "${scripts_folder}/a01_read_config.sh"

# Start lane pipeline log
mkdir -p "${combined_gvcfs_folder}"
mkdir -p "${combined_gvcfs_folder}/${set_id}_source_files"
log="${combined_gvcfs_folder}/${set_id}.log"

echo "WES library: combine gvcfs" > "${log}"
echo "${set_id}" >> "${log}" 
echo "Started: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}" 

echo "====================== Settings ======================" >> "${log}"
echo "" >> "${log}"

source "${scripts_folder}/a02_report_settings.sh" >> "${log}"

echo "=================== Pipeline steps ===================" >> "${log}"
echo "" >> "${log}"

# Submit job
slurm_time="--time=${time_to_request}"
slurm_account="--account=${account_to_use}"

sbatch "${slurm_time}" "${slurm_account}" \
  "${scripts_folder}/s01_combine_gvcfs.sb.sh" \
  "${job_file}" \
  "${scripts_folder}" \
  "${log}"

# Update pipeline log
echo "" >> "${log}"
echo "Submitted s01_combine_gvcfs: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}"