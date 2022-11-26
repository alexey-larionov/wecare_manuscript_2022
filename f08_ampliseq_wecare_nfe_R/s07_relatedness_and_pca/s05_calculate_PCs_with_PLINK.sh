#!/bin/bash

# s05_calculate_PCs_with_PLINK.sh
# Alexey Larionov, 29Dec2021

# Intended use:
# ./s05_calculate_PCs_with_PLINK.sh &> s05_calculate_PCs_with_PLINK.log

# Stop at runtime errors
set -e

# Start message
echo "Calculate PCs for ampliseq-nfe only dataset using PLINK (using 261 variants not in LD)"
date
echo ""

# Files and folders
base_folder="/Users/alexey/Documents"
project_folder="${base_folder}/wecare/final_analysis_2021/reanalysis_afterNov2021/ampliseq/s02_ampliseq_wecare_nfe"

scripts_folder="${project_folder}/scripts/s07_relatedness_and_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s07_relatedness_and_pca"

source_folder="${data_folder}/s04_not_in_ld"
source_dataset="${source_folder}/common_biallelic_autosomal_snps_in_HWE_not_in_LD"

output_folder="${data_folder}/s05_plink_pca"
rm -fr "${output_folder}"
mkdir "${output_folder}"

pca_results="${output_folder}/ampliseq_only_20PCs"

# Tools
plink="/Users/alexey/Documents/tools/plink/plink_1.9/plink1.9_beta6.20/plink"
"${plink}" --version
echo ""

# Calculate 20 top PCs using "header" and "tabs" options to format output
"${plink}" \
  --bfile "${source_dataset}" \
  --pca 20 header tabs \
  --allow-no-sex \
  --silent \
  --out "${pca_results}"

# Progress report
echo "Done"
date
echo ""
