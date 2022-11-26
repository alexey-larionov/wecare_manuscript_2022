#!/bin/bash

# s01_genotype_gvcfs.sh
# Started: Alexey Larionov, 26Feb2019
# Last updated: Alexey Larionov, 26Feb2019

# Use:
# sbatch s01_genotype_gvcfs.sh

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_genotype_gvcfs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_genotype_gvcfs.log
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
echo "Joined variant calling from Ampliseq panel and NFE WES"
date
echo ""

# Files and folders

scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

nfe_gvcf_folder="${data_folder}/s00_nfe_gvcfs"
ampliseq_gvcf_folder="${data_folder}/s09_gvcf/combined_gvcf"

raw_vcf_folder="${data_folder}/s10_raw_vcf"
raw_vcf="${raw_vcf_folder}/ampliseq_nfe.g.vcf.gz"
genotyping_log="${raw_vcf_folder}/ampliseq_nfe.log"

rm -fr "${raw_vcf_folder}" # remove output folder, if existed
mkdir -p "${raw_vcf_folder}"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Additional settings
maxAltAlleles=6
stand_call_conf=30.0
stand_emit_conf=30.0

# These settings are here for comparability with previous WES analysis
# Default GATK3 stand_call_conf is 10
# Note that --dontUseSoftClippedBases was used at the HC step

# Progress report
echo "--- Folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "nfe_gvcf_folder: ${nfe_gvcf_folder}"
echo "ampliseq_gvcf_folder: ${ampliseq_gvcf_folder}"
echo ""
echo "raw_vcf: ${raw_vcf}"
echo "genotyping_log: ${genotyping_log}"
echo ""
echo "--- Tools ---"
echo ""
echo "java: ${java}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "targets_interval_list: ${targets_interval_list}"
echo ""
echo "Started genotyping gvcfs ..."

# Genotype
"${java}" -Xmx72g -jar "${gatk}" \
  -T GenotypeGVCFs \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -maxAltAlleles "${maxAltAlleles}" \
  -stand_call_conf "${stand_call_conf}" \
  -stand_emit_conf "${stand_emit_conf}" \
  -nda \
  --downsampling_type NONE \
  -V "${nfe_gvcf_folder}/set1.g.vcf" \
  -V "${nfe_gvcf_folder}/set2.g.vcf" \
  -V "${ampliseq_gvcf_folder}/ampliseq_1.g.vcf.gz" \
  -V "${ampliseq_gvcf_folder}/ampliseq_2.g.vcf.gz" \
  -V "${ampliseq_gvcf_folder}/ampliseq_3.g.vcf.gz" \
  -V "${ampliseq_gvcf_folder}/ampliseq_4.g.vcf.gz" \
  -V "${ampliseq_gvcf_folder}/ampliseq_5.g.vcf.gz" \
  -V "${ampliseq_gvcf_folder}/ampliseq_6.g.vcf.gz" \
  -o "${raw_vcf}" \
  -nt 12 &>  "${genotyping_log}"

# Completion message
echo "Done"
date
echo ""
