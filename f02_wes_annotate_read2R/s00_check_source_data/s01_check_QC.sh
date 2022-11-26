#!/bin/bash

# s01_check_QC.sh
# Alexey Larionov, 19Sep2020

#SBATCH -J s01_check_QC
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s01_check_QC.log
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4
module load texlive/2015

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
echo "Started s01_check_QC: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s00_source_data"
stats_folder="${data_folder}/stats"
rm -fr "${stats_folder}"
mkdir "${stats_folder}"
scripts_folder="${project_folder}/scripts/s00_check_source_data"
cd "${scripts_folder}"

# Files
vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf/wecare_nfe_nov2016_vqsr_shf.vcf"
stats_file="${stats_folder}/wecare_nfe_nov2016_vqsr_shf.vchk"

# Tools
tools_folder="${base_folder}/tools"
bcftools_bin="${tools_folder}/bcftools/bcftools-1.10.2/bin"
python_bin="${tools_folder}/python/python_3.8.3/bin"
export PATH="${bcftools_bin}:${python_bin}:$PATH"

# Progress report
echo "vcf: ${vcf}"
echo "stats_folder: ${stats_folder}"
echo ""

# Compress
echo "Compressing ..."
bcftools view "${vcf}" \
--output-type z \
--output-file "${vcf}.gz"

# Index
echo "Indexing ..."
bcftools index "${vcf}.gz"

# Print header
echo "Extracting header ..."
bcftools view -h "${vcf}.gz" > "${vcf%.vcf}_header.txt"

# Count variants
echo ""
echo "Variant counts:"
echo ""
bcftools +counts "${vcf}.gz"

# Calculate bcfstats
echo ""
echo "Calculating bcfstats..."
echo ""
bcftools stats -s- "${vcf}.gz" > "${stats_file}"

# Plot the stats (PDF requires texlive)
echo "Making plots..."
plot-vcfstats -p "${stats_folder}" "${stats_file}"
echo ""

# Specific annotations
annotations="${vcf%.vcf}_annotations.txt"
bcftools query -H -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%FILTER\n' "${vcf}.gz" > "${annotations}"

echo "--- FILTER ---"
echo ""
awk 'NR>1 {print $6}' "${annotations}" | sort |  uniq -c | sort -nr
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
