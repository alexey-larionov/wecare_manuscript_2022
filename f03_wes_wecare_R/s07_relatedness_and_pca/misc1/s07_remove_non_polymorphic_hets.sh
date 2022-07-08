#!/bin/bash

# s07_remove_non_polymorphic_hets.sh
# Remove non-polymorphic heterozygous sites
# Alexey Larionov, 05Oct2020

#SBATCH -J s07_remove_non_polymorphic_hets
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s07_remove_non_polymorphic_hets.log
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
echo "Started s07_remove_non_polymorphic_hets"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s05_pca/s01_vcf"
scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare_altok_filltags_polymorphic.vcf.gz"
output_vcf="${data_folder}/wecare_altok_filltags_polymorphic_only.vcf.gz"
output_log="${data_folder}/wecare_altok_filltags_polymorphic_only.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Source vcf counts"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

echo "Excluding sites with no homozygous genotypes: i.e. removes non-polymorphic heterozygous."
echo "Still there could be a problem with non-polymorphic hemizygous (e.g. haploid on Y chromosome); "
echo "However this problem was not present in the current wecare dataset (verified by in-house R script)."
"${bcftools}" view "${source_vcf}" \
--output-file "${output_vcf}" \
--exclude 'COUNT(GT="hom")=0' \
--output-type z \
--threads 4 \
&> "${output_log}"

# --exclude 'INFO/AC_Hom=0' doesnt work; probably fill-tags does something different about AC_Hom

# Index the vcf file with new tags
"${bcftools}" index "${output_vcf}"

echo ""
echo "Counts in the vcf file with new tags"
"${bcftools}" +counts "${output_vcf}"
echo ""

# Completion message
echo "Done"
date
echo ""
