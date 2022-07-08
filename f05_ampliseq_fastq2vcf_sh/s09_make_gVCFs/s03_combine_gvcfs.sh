#!/bin/bash

# s03_combine_gvcfs.sh
# Started: Alexey Larionov, 29Jun2018
# Last updated: Alexey Larionov, 01Mar2019

# Use:
# sbatch s03_combine_gvcfs.sh

# This script launches another one, 
# which conbines gVCFs in batches (up to 100 per batch)   

# Assuming that GATK will use single thread per analysis 
# (no parallelising available for GATK3 Combine gVCFs)
# and up to 30GB memory per thread for processing each batch, 
# it should be OK to run all batches in parallel on a 
# single node on cluster (32 cores & 192 GB RAM per node)

# Takes less than 5 min

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s03_combine_gvcfs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s03_combine_gvcfs.log
#SBATCH --ntasks=6
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
echo "Launch combining gVCFs in batches"
date
echo ""

# Files and folders
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"

data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
gvcf_folder="${data_folder}/s09_gvcf/gvcf"
combined_gvcf_folder="${data_folder}/s09_gvcf/combined_gvcf"

#rm -fr "${combined_gvcf_folder}" # remove output folder, if existed
mkdir -p "${combined_gvcf_folder}"

combined_gvcf="${combined_gvcf_folder}/ampliseq.g.vcf.gz"
gatk_log="${combined_gvcf_folder}/ampliseq.log"

# Tools and resources
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
#targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo "gvcf_folder: ${gvcf_folder}"
echo "combined_gvcf_folder: ${combined_gvcf_folder}"
echo ""
echo "combined_gvcf: ${combined_gvcf}"
echo "gatk_log: ${gatk_log}"
echo ""
echo "--- Tools ---"
echo ""
echo "java: ${java}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
#echo "targets_interval_list: ${targets_interval_list}"
echo ""

# Make list of source gVCF files 
cd "${gvcf_folder}"
source_gVCF_files=$(ls *.g.vcf.gz)
echo "Detected $(wc -w <<< ${source_gVCF_files}) gVCF files in the source folder"
echo ""

# Compile list of gvcf files
source_gvcfs=""
for file in ${source_gVCF_files}
do
  source_gvcfs="${source_gvcfs} -V ${file}"
done
  
# Combine gVCFs 
# Note that source gVCFs are provided within variable (no quotetion marks!)
# Note suppressing downsampling (because of Ampliseq)
echo "Started genotyping ..."
echo ""

"${java}" -Xmx30g -jar "${gatk}" \
  -T CombineGVCFs \
  -R "${ref_genome}" \
  ${source_gvcfs} \
  -o "${combined_gvcf}" \
  --downsampling_type NONE \
  &> "${gatk_log}"

# -L "${targets_interval_list}" -ip 10 \

# Completion message
echo "Done"
date
echo ""
