#!/bin/bash

# s01_split_multialelic_sites.sh
# Alexey Larionov, 07Sep2020

#SBATCH -J s01_split_multialelic_sites
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=05:00:00
#SBATCH --output=s01_split_multialelic_sites.log

##SBATCH --qos=INTR

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
echo "Started s01_split: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"

project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

scripts_folder="${project_folder}/scripts/s01_split"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s01_split"
rm -fr "${data_folder}"
mkdir -p "${data_folder}"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# Resources
resources_folder="${base_folder}/resources"
decompressed_bundle_folder="${resources_folder}/gatk_bundle/b37/decompressed"
ref_genome="${decompressed_bundle_folder}/human_g1k_v37.fasta"

targets_folder="${resources_folder}/illumina_nextera"
targets_intervals="${targets_folder}/nexterarapidcapture_exome_targetedregions_v1.2.b37.intervals"

# Files
source_vcf="${project_folder}/data/s00_source_data/wecare_nfe_nov2016_vqsr_shf/wecare_nfe_nov2016_vqsr_shf.vcf"
split_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split.vcf"
split_log="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split.log"

# Count variants
echo "Variant counts before splitting:"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

# Split variants
echo "Splitting multiallelic variants ..."
# Split ma sites
"${java}" -Xmx60g -jar "${gatk}" \
  -T LeftAlignAndTrimVariants \
  -R "${ref_genome}" \
  -L "${targets_intervals}" -ip 10 \
  -V "${source_vcf}" \
  -o "${split_vcf}" \
  --splitMultiallelics &> "${split_log}"
echo ""

# Count variants
echo "Variant counts after splitting: "
echo ""
"${bcftools}" +counts "${split_vcf}"
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
