#!/bin/bash

# s02_remove_dot_alt.sh
# Remove sites with dot in ALT
# Alexey Larionov, 05Oct2020

#SBATCH -J s02_remove_dot_alt
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s02_remove_dot_alt.log
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
echo "Started s02_remove_dot_alt"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s05_pca/s01_vcf"
scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare.vcf.gz"
output_vcf="${data_folder}/wecare_altok.vcf.gz"
output_log="${data_folder}/wecare_altok.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Source vcf counts"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

echo "Selecting wecare samples ..."
echo ""
"${bcftools}" view "${source_vcf}" \
--exclude 'ALT="."' \
--output-file "${output_vcf}" \
--output-type z \
--threads 4 \
&> "${output_log}"

# Removal of samples creates a number of non-polymorphic variant sites
# e.g. sites where all genotypes in the dataset are homozygous reference.
# --trim-alt-alleles puts "." to ALT alleles of such non-polymorphic sites;
# Now these sites are removed

# Index wecare vcf
"${bcftools}" index "${output_vcf}"

echo "Counts in the vcf file after removal; of sites with dot in ALT"
"${bcftools}" +counts "${output_vcf}"
echo ""

# Completion message
echo "Done"
date
echo ""
