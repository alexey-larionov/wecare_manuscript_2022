#!/bin/bash

# s01_hard_filters.sh
# Started: Alexey Larionov, 16Mar2019
# Last updated: Alexey Larionov, 18Mar2019

# Use:
# sbatch s01_hard_filters.sh

# Add hard filters to the FILTER column

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_hard_filters
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_hard_filters.log
#SBATCH --ntasks=4
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
echo "Hard filters for Ampliseq-NFE"
date
echo ""

# Files and folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

vqsr_vcf_folder="${data_folder}/s11_vqsr"
hf_folder="${data_folder}/s12_hard_filters"

rm -fr "${hf_folder}" # remove results folder, if existed
mkdir -p "${hf_folder}"

vqsr_vcf="${vqsr_vcf_folder}/ampliseq_nfe_locID_MAflag_vqsr.vcf"
hf_vcf="${hf_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf.vcf"
gatk_log="${hf_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf.log"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"

# Settings
MIN_DP="7390.0"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "vqsr_vcf: ${vqsr_vcf}"
echo "hf_vcf: ${hf_vcf}"
echo "gatk_log: ${gatk_log}"
echo ""
echo "--- Tools ---"
echo ""
echo "gatk: ${gatk}"
echo "java: ${java}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "targets_interval_list: ${targets_interval_list}"
echo ""
echo "--- Settings ---"
echo ""
echo "MIN_DP: ${MIN_DP}"
echo ""

# Applying hard filters
echo "Applying hard filters ..."

# Filtering SNPs
"${java}" -Xmx60g -jar "${gatk}" \
  -T VariantFiltration \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${vqsr_vcf}" \
  -o "${hf_vcf}" \
  --filterName "DP_LESS_THAN_${MIN_DP}" \
  --filterExpression "DP < ${MIN_DP}" \
  --downsampling_type NONE \
  &>  "${gatk_log}"

# Progress report
echo "Done"
date
echo ""
