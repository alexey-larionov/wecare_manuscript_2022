#!/bin/bash

# s01_fastqc_after_trimming.sh
# FastQC wecare ampliseq samples
# Started: Alexey Larionov, 15Jun2018
# Last updated: Alexey Larionov, 17Oct2018

# Use:
# sbatch s01_fastqc_after_trimming.sh

# Split all files to batches of up to 30 files  
# Run fastqc for each batch in parallel 
# 32 cores & 192 GB RAM per cpu skylake node (384 GB RAM if himem)

# Takes ~20-30 min

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_fastqc_after_trimming
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=s01_fastqc_after_trimming.log
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
echo "FastQC afetr trimming"
date
echo ""

# Add fastqc v0.11.7 to PATH
PATH=/rds/project/erf33/rds-erf33-medgen/tools/fastqc/fastqc_v0.11.7:$PATH
fastqc --version
echo ""

# Files and folders
base_folder="/rds/project/erf33/rds-erf33-medgen/users/alexey/wecare_ampliseq/analysis3"
fastq_folder="${base_folder}/data_and_results/s03_trimmed_fastq/fastq"
fastqc_folder="${base_folder}/data_and_results/s04_qc_after_trimming/fastqc"
rm -fr "${fastqc_folder}" # remove folder if existed
mkdir -p "${fastqc_folder}"

# Progress report
echo "base_folder: ${base_folder}"
echo "fastq_folder: ${fastq_folder}"
echo "fastqc_folder: ${fastqc_folder}"
echo ""

# Make list of fastq files 
cd "${fastq_folder}"
fastq_files=$(ls *trim.fastq.gz)

# Make batches of 30 files (store temporary files in output folder)
cd "${fastqc_folder}"
split -l 30 <<< "${fastq_files}"
batches=$(ls)

# Progress report
echo "Made "$(wc -w <<< $batches)" batches of up to 30 files"
echo ""

# Initialise batch counter
batch_no=0

# For each batch
for batch in $batches
do
  
  # Get list of fastq files in batch
  fastqs=$(cat $batch)

  # For each fastq file in batch
  for fastq in $fastqs
  do
  
    # Start fstqc in the background (not wait for completion)
    fastqc --quiet --extract -o "${fastqc_folder}" "${fastq_folder}/${fastq}" &
    
  done # next fastq in the batch
  
  # Whait until the batch (all background processes) completed
  wait
  
  # Progress report
  batch_no=$(( $batch_no + 1 ))
  echo "$(date +%H:%M:%S) Done batch ${batch_no}"
  
done # next batch

# Remove temporary batch files from output folder
rm ${batches}

# Completion message
echo ""
echo "Done all tasks"
date
echo ""
