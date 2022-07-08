#!/bin/bash

# s05_annotate_with_vep.sh
# Alexey Larionov, 09Sep2020

#SBATCH -J s05_annotate_with_vep
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=01:00:00
#SBATCH --output=s05_annotate_with_vep.log
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Allocated node: $(hostname)"
echo "$(date)"
echo ""
echo "Job name: ${SLURM_JOB_NAME}"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo " ------------------ Job progress ------------------ "
echo ""

# Stop at runtime errors
set -e

# Start message
echo "Started s05_annotate_with_vep: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s02_annotate"
scripts_folder="${project_folder}/scripts/s02_annotate"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar.vcf.gz"
vep_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep.vcf.gz"
vep_log="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep.log"
vep_report="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep.html"

# Tools
tools_folder="${base_folder}/tools"
vep="${tools_folder}/vep/v101_b37/ensembl-vep/vep"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# PATH and PERL5LIB
export PATH="${tools_folder}/htslib/htslib-1.10.2/bin:$PATH"
export PERL5LIB="${tools_folder}/vep/v101_b37/cpanm/lib/perl5:$PERL5LIB"

# VEP cache
cache_folder="${tools_folder}/vep/v101_b37/ensembl-vep/cache"
cache_version="101"
cache_assembly="GRCh37"

# Plugins folder
plugins_folder="${tools_folder}/vep/v101_b37/ensembl-vep/plugins"

# Resources
resources_folder="${base_folder}/resources"

decompressed_bundle_folder="${resources_folder}/gatk_bundle/b37/decompressed"
b37_fasta="${decompressed_bundle_folder}/human_g1k_v37.fasta"

cadd_data_folder="${resources_folder}/cadd/v1.6_b37"
cadd_snv_data="${cadd_data_folder}/whole_genome_SNVs.tsv.gz"
cadd_indels_data="${cadd_data_folder}/InDels.tsv.gz"

#revel_data_folder="${resources_folder}/revel"
#revel_data="${revel_data_folder}/new_tabbed_revel.tsv.gz"

# Num of threads
n_threads="8"

# File to copy information about VEP cache
#vep_cache_info="${data_folder}/s05_vep_cache_info.txt"

# Progress report
echo "--- Settings ---"
echo ""
echo "source_vcf: ${source_vcf}"
echo "vep_vcf: ${vep_vcf}"
echo "vep_log: ${vep_log}"
echo "vep_report: ${vep_report}"
echo ""
echo "n_threads: ${n_threads}"
echo ""
echo "--- Data sources ---"
echo ""
echo "cache_folder: ${cache_folder}"
echo "cache_version: ${cache_version}"
echo "cache_assembly: ${cache_assembly}"
echo ""
echo "b37_fasta: ${b37_fasta}"
echo ""
#echo "See used VEP cache description in the following file:"
#echo "${vep_cache_info}"
#echo ""
echo "plugins_folder: ${plugins_folder}"
echo ""
echo "CADD annotation files:"
echo "${cadd_snv_data}"
echo "${cadd_indels_data}"
echo ""
#echo "REVEL annotation files:"
#echo "${revel_data}"
#echo ""
echo "Working..."

# Keep information about used VEP cache
# copy used versions of different program into the new cache_info file
#cp "${cache_folder}/homo_sapiens/98_GRCh38/info.txt" "${vep_cache_info}"

# Annotate VCF
"${vep}" \
  --input_file "${source_vcf}" \
  --output_file "${vep_vcf}" \
  --vcf \
  --force_overwrite \
  --compress_output bgzip \
  --stats_file "${vep_report}" \
  --fork "${n_threads}" \
  --offline \
  --cache \
  --dir_cache "${cache_folder}" \
  --cache_version "${cache_version}" \
  --species homo_sapiens \
  --assembly "${cache_assembly}" \
  --fasta "${b37_fasta}" \
  --check_ref \
  --everything \
  --total_length \
  --check_existing \
  --exclude_null_alleles \
  --pick \
  --gencode_basic \
  --nearest symbol \
  --dir_plugins "${plugins_folder}" \
  --plugin CADD,"${cadd_snv_data}","${cadd_indels_data}" \
  &> "${vep_log}"

#  --plugin REVEL,"${revel_data}" \ # look at b37/38 data ...

# Index annotated vcf
"${bcftools}" index "${vep_vcf}"

# List added VEP annotations
echo ""
echo "Added VEP annotations:"
echo ""
"${bcftools}" +split-vep -l "${vep_vcf}"
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
