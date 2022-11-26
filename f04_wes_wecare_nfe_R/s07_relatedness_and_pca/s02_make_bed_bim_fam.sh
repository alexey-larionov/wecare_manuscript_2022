#!/bin/bash

# s02_make_plink_bed.sh
# Convert to binary plink format and do some additional filtering:
# Keep autosomes only and ensure MAF < 0.05 in this dataset
# (the prevous filtering was by gnomaD NFE AF)
# The script requires that call rates are >70% for both: variants and samples
# This is less stringent than had been filtered earlier in this dataset (~80 - 85%)
# and less stringent than shown on some examples (90%)

# Alexey Larionov, 31Jan2021

# Intended use:
# ./s02_make_bed_bim_fam.sh &> s02_make_bed_bim_fam.log

# Reference
# http://zzz.bwh.harvard.edu/plink/data.shtml#bed

# Stop at runtime errors
set -e

# Start message
echo "Convert plink ped to binary format"
date
echo ""

# Folders
base_folder="/Users/alexey/Documents"
project_folder="${base_folder}/wecare/final_analysis_2021/reanalysis_wo_danish_2021/s02_wes_wecare_nfe"

scripts_folder="${project_folder}/scripts/s07_relatedness_and_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s07_relatedness_and_pca"
source_folder="${data_folder}/s01_ped_map"
output_folder="${data_folder}/s02_bed_bim_fam"
rm -fr "${output_folder}"
mkdir "${output_folder}"

# Files
source_fileset="${source_folder}/common_biallelic_snps_in_HWE"
output_fileset="${output_folder}/common_biallelic_autosomal_snps_in_HWE"

# Plink
plink19="${base_folder}/tools/plink/plink_1.9/plink_1.9-beta6.10/plink"

# Make bed-bim-fam
"${plink19}" \
--file "${source_fileset}" \
--autosome \
--geno 0.3 \
--maf 0.05 \
--mind 0.3 \
--silent \
--make-bed \
--out "${output_fileset}"

# --geno / --mind max proportion of missed data per variant/individual
# --1 option could be used is phenotype was coded 0 = unaffected, 1 = affected

# Completion message
echo "Done"
date
