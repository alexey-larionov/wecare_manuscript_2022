#!/bin/bash

# s03_fill_tags.sh
# Recalculate AC, AN, AF etc after removal of samples
# Alexey Larionov, 05Oct2020

#SBATCH -J s03_fill_tags
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s03_fill_tags.log
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
echo "Started s03_fill_tags"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s05_pca/s01_vcf"
scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare_altok.vcf.gz"
output_vcf="${data_folder}/wecare_altok_filltags.vcf.gz"
output_log="${data_folder}/wecare_altok_filltags.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Source vcf counts"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

echo "Recalculating tags after samples removal (AC,AN,AF etc) ..."
"${bcftools}" +fill-tags "${source_vcf}" \
--output "${output_vcf}" \
--output-type z \
--threads 4 \
&> "${output_log}"

# Removal of samples creates may mess with thhe AC, AN, AF etc
# Here we recalculate these tags

# Index wecare vcf
"${bcftools}" index "${output_vcf}"

echho ""
echo "Counts in the vcf file after recalculating tags"
"${bcftools}" +counts "${output_vcf}"
echo ""

# Completion message
echo "Done"
date
echo ""
