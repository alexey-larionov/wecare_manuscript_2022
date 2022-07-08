#!/bin/bash

# s02_add_ids.sh
# Alexey Larionov, 05Mar2021

# Add variant IDs

#SBATCH -J s02_add_ids
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s02_add_ids.log
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
echo "Started s01_add_ids: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020/ampliseq"
data_folder="${project_folder}/data/s02_annotate"
scripts_folder="${project_folder}/scripts/s02_annotate"
cd "${scripts_folder}"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# Files
source_vcf="${data_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_split_clean_tag_ac.vcf.gz"
id_vcf="${data_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_split_clean_tag_ac_id.vcf.gz"
id_log="${data_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_split_clean_tag_ac_id.log"

echo "Adding variant IDs ..."
echo ""
"${bcftools}" annotate "${source_vcf}" \
  --set-id '%CHROM\_%POS\_%REF\_%ALT' \
  --output "${id_vcf}" \
  --output-type z \
  --threads 4 \
  &> "${id_log}"

# Index output vcf
"${bcftools}" index "${id_vcf}"

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
