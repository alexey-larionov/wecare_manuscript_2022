#!/bin/bash

# s03_check_clinvar_chr.sh
# Alexey Larionov, 05Mar2021

# Check consistency of chromosome naming in the data and ClinVar

#SBATCH -J s03_check_clinvar_chr
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s03_check_clinvar_chr.log
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
echo "Check consistency of chromosome naming in the data and ClinVar"
date
echo ""
echo "The script checks whether data and ClinVar use 1,2,3... or chr1,chr2,chr3... style for chromosome naming"
echo ""

# Start message
echo "Started s03_check_clinvar_chr: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
clinvar_folder="${base_folder}/resources/clinvar/vcf_GRCh37/v20200905"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020/ampliseq"
data_folder="${project_folder}/data/s02_annotate"
scripts_folder="${project_folder}/scripts/s02_annotate"
cd "${scripts_folder}"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# Files
data_vcf="${data_folder}/ampliseq_nfe_locID_MAflag_vqsr_hf_split_clean_tag_ac_id.vcf.gz"
clinvar_vcf="${clinvar_folder}/clinvar_20200905.vcf.gz"

echo "Chromosome style in data_vcf"
echo "${data_vcf}"
echo ""
"${bcftools}" view -h "${data_vcf}" | grep "^##contig"
echo ""

echo "Chromosome style in clinvar_vcf"
echo "${clinvar_vcf}"
echo ""
"${bcftools}" view -h "${clinvar_vcf}" | grep "^##contig"
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
