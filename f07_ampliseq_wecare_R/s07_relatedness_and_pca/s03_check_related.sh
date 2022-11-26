#!/bin/bash

# s03_check_related.sh
# Calculate KING coefcient and remove relatives
# Alexey Larionov, 23Dec2021

# Intended use:
# ./s03_check_related.sh &> s03_check_related.log

# One expected duplicate (281 and 280) was detected
# (both copies should be retained in analysis - as explained by US collaborators):
# 281 - 280 : 0.496

# Several unexpected 1st degree related cases were suggested;
# Even more spurious "relations" was detected later in ampliseq-nfe analysis
# that used even smaller number of variants;
# So, it was decided to ignore the relation detection step in Ampliseq analysis.

# Expected KING coefficients for relatives
# 0.5 (2^-1) Duplicates (identical tweens)
# 0.25 (2^-2) First-degree relatives (parent-child, full siblings)
# 0.125 (2^-3) 2-nd degree relatives (example?)
# 0.0625 (2^-4) 3-rd degree relatives (example?)
# Parameter 0.0441941738241592=1/2^-4.5 was used in Preve 2020

# Cutoff 0.25 was used for the simplifyed procedure because of the small number of variants
# Stricter thresholds produced many tens of apparently spurious related pairs

# References
# http://www.cog-genomics.org/plink/2.0/distance#make_king
# https://www.cog-genomics.org/plink/2.0/formats#kin0

# How does it "handle" rare variants ??

# Stop at runtime errors
set -e

# Start message
echo "Detect and remove related cases (if any) using KING coefficient"
date
echo ""

# Folders
base_folder="/Users/alexey/Documents"
project_folder="${base_folder}/wecare/final_analysis_2021/reanalysis_afterNov2021/ampliseq/s01_ampliseq_wecare_only"

scripts_folder="${project_folder}/scripts/s07_relatedness_and_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s07_relatedness_and_pca"
source_folder="${data_folder}/s02_bed_bim_fam"
output_folder="${data_folder}/s03_check_related"
rm -fr "${output_folder}"
mkdir "${output_folder}"

# Files
source_fileset="${source_folder}/common_biallelic_autosomal_snps_in_HWE"
output_fileset="${output_folder}/common_biallelic_autosomal_snps_in_HWE_norel"

# Plink
plink2="${base_folder}/tools/plink/plink2/plink2_alpha2.3/plink2"

# Calculate and remove related samples
"${plink2}" \
--bfile "${source_fileset}" \
--allow-extra-chr \
--make-king-table \
--king-table-filter 0.25 \
--make-bed \
--king-cutoff 0.25 \
--silent \
--out "${output_fileset}"

# Completion message
echo "Done"
date
