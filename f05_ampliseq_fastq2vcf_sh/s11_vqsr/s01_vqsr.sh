#!/bin/bash

# s01_vqsr.sh
# Started: Alexey Larionov, 07Aug2018
# Last updated: Alexey Larionov, 17Mar2019

# Use:
# sbatch s01_vqsr.sh

# VQSR raw VCF

# Note that a customised R installation is used (with some R libraries pre-installed)

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_vqsr
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s01_vqsr.log
#SBATCH --ntasks=4
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4 

module load gcc/5.2.0
module load boost/1.50.0
module load texlive/2015
module load pandoc/1.15.2.1
export PATH=/rds/project/erf33/rds-erf33-medgen/tools/r/R-3.3.2/bin:$PATH

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
echo "VQSR for Ampliseq panel and NFE WES"
date
echo ""

# Folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

raw_vcf_folder="${data_folder}/s10_raw_vcf"

vqsr_folder="${data_folder}/s11_vqsr"
vqsr_tmp_folder="${vqsr_folder}/temp"

#rm -fr "${vqsr_folder}" # remove results folder, if existed
rm -fr "${vqsr_tmp_folder}" # remove tmp folder, if existed
mkdir -p "${vqsr_tmp_folder}"

# Sourse file
raw_vcf="${raw_vcf_folder}/ampliseq_nfe_locID_MAflag.vcf"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
hapmap="${resources_folder}/gatk_bundle/b37/decompressed/hapmap_3.3.b37.vcf"
omni="${resources_folder}/gatk_bundle/b37/decompressed/1000G_omni2.5.b37.vcf"
phase1_1k_hc="${resources_folder}/gatk_bundle/b37/decompressed/1000G_phase1.snps.high_confidence.b37.vcf"
dbsnp_138="${resources_folder}/gatk_bundle/b37/decompressed/dbsnp_138.b37.vcf"
mills="${resources_folder}/gatk_bundle/b37/decompressed/Mills_and_1000G_gold_standard.indels.b37.vcf"

# Settings
SNP_TS="97.0"
INDEL_TS="95.0"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo "vqsr_tmp_folder: ${vqsr_tmp_folder}"
echo ""
echo "raw_vcf: ${raw_vcf}"
echo ""
echo "--- Tools ---"
echo ""
echo "gatk: ${gatk}"
echo "java: ${java}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "hapmap: ${hapmap}"
echo "omni: ${omni}"
echo "phase1_1k_hc: ${phase1_1k_hc}"
echo "dbsnp_138: ${dbsnp_138}"
echo ""
echo "targets_interval_list: ${targets_interval_list}"
echo ""
echo "--- Settings ---"
echo ""
echo "SNP_TS: ${SNP_TS}"
echo "INDEL_TS: ${INDEL_TS}"
echo ""

# --- Train vqsr snp model --- #

# Progress report
echo "Training vqsr snp model ..."

# File names
recal_snp="${vqsr_tmp_folder}/ampliseq_nfe_snp.recal"
plots_snp="${vqsr_tmp_folder}/ampliseq_nfe_snp_plots.R"
tranches_snp="${vqsr_tmp_folder}/ampliseq_nfe_snp.tranches"
log_train_snp="${vqsr_tmp_folder}/ampliseq_nfe_snp_train.log"

# Train vqsr snp model
"${java}" -Xmx20g -jar "${gatk}" \
  -T VariantRecalibrator \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -input "${raw_vcf}" \
  -AS \
  --downsampling_type NONE \
  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
  -recalFile "${recal_snp}" \
  -tranchesFile "${tranches_snp}" \
  -rscriptFile "${plots_snp}" \
  --target_titv 3.2 \
  -mode SNP \
  -tranche 100.0 -tranche 99.0 -tranche 97.0 -tranche 95.0  -tranche 90.0 \
  -nt 4 &>  "${log_train_snp}"

# -AS - use allele-specific annotations (not needed, but kept for consistency)
#  -an InbreedingCoeff

# --- Apply vqsr snp model --- #

# Progress report
echo "Applying vqsr snp model ..."

# File names
vqsr_snp_vcf="${vqsr_tmp_folder}/ampliseq_nfe_snp_vqsr.vcf"
log_apply_snp="${vqsr_tmp_folder}/ampliseq_nfe_snp_apply.log"

# Apply vqsr snp model
"${java}" -Xmx24g -jar "${gatk}" \
  -T ApplyRecalibration \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -input "${raw_vcf}" \
  -AS \
  --downsampling_type NONE \
  -recalFile "${recal_snp}" \
  -tranchesFile "${tranches_snp}" \
  -o "${vqsr_snp_vcf}" \
  --ts_filter_level "${SNP_TS}" \
  -mode SNP \
  -nt 4 &>  "${log_apply_snp}"  

# --- Train vqsr indel model --- #

# Progress report
echo "Training vqsr indel model ..."

# File names
recal_indel="${vqsr_tmp_folder}/ampliseq_nfe_indel.recal"
plots_indel="${vqsr_tmp_folder}/ampliseq_nfe_indel_plots.R"
tranches_indel="${vqsr_tmp_folder}/ampliseq_nfe_indel.tranches"
log_train_indel="${vqsr_tmp_folder}/ampliseq_nfe_indel_train.log"

# Train vqsr indel model
"${java}" -Xmx24g -jar "${gatk}" \
  -T VariantRecalibrator \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -input "${vqsr_snp_vcf}" \
  -AS \
  --downsampling_type NONE \
  -resource:mills,known=false,training=true,truth=true,prior=12.0 "${mills}" \
  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
  -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum -an InbreedingCoeff \
  -recalFile "${recal_indel}" \
  -tranchesFile "${tranches_indel}" \
  -rscriptFile "${plots_indel}" \
  -tranche 100.0 -tranche 99.0 -tranche 97.0 -tranche 95.0 -tranche 90.0 \
  --maxGaussians 4 \
  -mode INDEL \
  -nt 4 &>  "${log_train_indel}"

# --- Apply vqsr indel model --- #

# Progress report
echo "Applying vqsr indel model..."

# File names
out_vcf="${vqsr_folder}/ampliseq_nfe_locID_MAflag_vqsr.vcf"
log_apply_indel="${vqsr_tmp_folder}/ampliseq_nfe_indel_apply.log"

# Apply vqsr indel model
"${java}" -Xmx24g -jar "${gatk}" \
  -T ApplyRecalibration \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -input "${vqsr_snp_vcf}" \
  -AS \
  --downsampling_type NONE \
  -recalFile "${recal_indel}" \
  -tranchesFile "${tranches_indel}" \
  -o "${out_vcf}" \
  --ts_filter_level "${INDEL_TS}" \
  -mode INDEL \
  -nt 4 &>  "${log_apply_indel}"  

# Progress report
echo "Done all tasks"
date
echo ""
