#!/bin/bash

# s04_remove_non_polymorphic_homs.sh
# Remove non-polymorphic homozygous sites
# Alexey Larionov, 05Oct2020

#SBATCH -J s04_remove_non_polymorphic_homs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s04_remove_non_polymorphic_homs.log
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
echo "Started s04_remove_non_polymorphic_homs"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s05_pca/s01_vcf"
scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare_altok_filltags.vcf.gz"
output_vcf="${data_folder}/wecare_altok_filltags_polymorphic.vcf.gz"
output_log="${data_folder}/wecare_altok_filltags_polymorphic.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Source vcf counts"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

echo "Excluding variants with AC=0 in minor allele: removes non-polymorphic homozygous (RR or AA)"
echo "Importantly: still preserves non-polymorphic heterozygous (AR)"

"${bcftools}" view "${source_vcf}" \
--output-file "${output_vcf}" \
--min-ac 1:minor \
--output-type z \
--threads 4 \
&> "${output_log}"

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
