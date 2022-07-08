#!/bin/bash

# s03_count_N_reads.sh
# Started: Alexey Larionov, 26Jun2018
# Last updated: Alexey Larionov, 18Oct2018

# Use:
# sbatch s03_count_N_reads.sh

# Takes ~1.5hrs 
# Could be paralelised to speed up
# but I desided not to bother

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s03_count_N_reads
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=03:00:00
#SBATCH --output=s03_count_N_reads.log
#SBATCH --ntasks=6

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
echo "Conunt 35/27 x N reads before trimming"
date
echo ""

# Files and folders
base_folder="/rds/project/erf33/rds-erf33-medgen/users/alexey/wecare_ampliseq/analysis3"

fastq_folder="${base_folder}/data_and_results/s03_trimmed_fastq/fastq"
output_folder="${base_folder}/data_and_results/s04_qc_after_trimming/count_N_reads"

rm -fr "${output_folder}" # remove folder if existed
mkdir -p "${output_folder}"

counts_file="${output_folder}/count_N_reads.txt"

# Progress report
echo "base_folder: ${base_folder}"
echo "fastq_folder: ${fastq_folder}"
echo "counts_file: ${counts_file}"
echo ""

# Make list of fastq files 
cd "${fastq_folder}"
R1_fastq_files=$( ls *R1_trim.fastq.gz )
R2_fastq_files=$( ls *R2_trim.fastq.gz )

echo "Found $(wc -w <<< ${R1_fastq_files}) R1 fastq files"
echo "Found $(wc -w <<< ${R2_fastq_files}) R2 fastq files"

# Initialise output file
echo -e "sample_no\tillumina_id\tread_no\tlane_no\ttotal_reads\tn_reads" > "${counts_file}"

# For each R1 fastq file
for fastq in $R1_fastq_files
do
  
  # Parce the file name 
  IFS="_" read sample_no illumina_id lane_no read_no etc <<< ${fastq}
  
  # Total count of reads
  total_reads=$(( $(zcat "${fastq}" | wc -l) / 4 ))
  
  # N35 reads (note that grep -c does NOT generate 0 if it finds nothing ...)
  n35_reads=$( zgrep NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN "${fastq}" | wc -l )
  
  # Write result to output file
  echo -e "$sample_no\t$illumina_id\t$read_no\t$lane_no\t$total_reads\t$n35_reads" >> "${counts_file}"
  
done # next fastq file

# For each R2 fastq file
for fastq in $R2_fastq_files
do
  
  # Parce the file name 
  IFS="_" read sample_no illumina_id lane_no read_no etc <<< ${fastq}
  
  # Total count of reads
  total_reads=$(( $(zcat "${fastq}" | wc -l) / 4 ))
  
  # N35 reads (note that grep -c does NOT generate 0 if it finds nothing ...)
  n27_reads=$( zgrep NNNNNNNNNNNNNNNNNNNNNNNNNNN "${fastq}" | wc -l )
  
  # Write result to output file
  echo -e "$sample_no\t$illumina_id\t$read_no\t$lane_no\t$total_reads\t$n27_reads" >> "${counts_file}"
  
done # next fastq file

# Explore results
echo "Explore result"
head "${counts_file}"
echo ""
tail "${counts_file}"
echo ""
grep ^45 "${counts_file}"
echo ""

# Completion message
echo "Done all fastq files"
date
echo ""
