#!/bin/bash

# s04_exclude_variants_in_LD_with_PLINK.sh
# Alexey Larionov, 29Dec2021

# Because of spurious "relatedness" detected with small number of variants,
# the relatedness detection step was omitted

# Intended use:
# ./s04_exclude_variants_in_LD_with_PLINK.sh &> s04_exclude_variants_in_LD_with_PLINK.log

# Stop at runtime errors
set -e

# Start message
echo "Exclude variants in LD"
date
echo ""

# Files and folders
base_folder="/Users/alexey/Documents"
project_folder="${base_folder}/wecare/final_analysis_2021/reanalysis_afterNov2021/ampliseq/s02_ampliseq_wecare_nfe"

scripts_folder="${project_folder}/scripts/s07_relatedness_and_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s07_relatedness_and_pca"

source_folder="${data_folder}/s02_bed_bim_fam"
source_dataset="${source_folder}/common_biallelic_autosomal_snps_in_HWE"

output_folder="${data_folder}/s04_not_in_ld"
rm -fr "${output_folder}"
mkdir "${output_folder}"

pairphase_LD="${output_folder}/pairphase_LD"
LD_pruned_dataset="${output_folder}/common_biallelic_autosomal_snps_in_HWE_not_in_LD"

# Tools
plink="/Users/alexey/Documents/tools/plink/plink_1.9/plink1.9_beta6.20/plink"
"${plink}" --version
echo ""

# Determine variants in LD
# Command indep-pairphse makes two files:
# - list of variants in LD (file with extension .prune.out)
# - list of cariants not in LD (extension .prune.in)

# --indep-pairphase is just like --indep-pairwise,
# except that its r2 values are based on maximum likelihood phasing
# http://www.cog-genomics.org/plink/1.9/ld#indep

# The specific parameters 50 5 0.5 are taken from an example
# discussed in PLINK 1.07 manual for LD prunning
# http://zzz.bwh.harvard.edu/plink/summary.shtml#prune
# It does the following:
# a) considers a window of 50 SNPs
# b) calculates LD between each pair of SNPs in the window
# c) removes one of a pair of SNPs if the LD is greater than 0.5
# d) shifts the window 5 SNPs forward and repeat the procedure

"${plink}" \
  --bfile "${source_dataset}" \
  --indep-pairphase 50 5 0.5 \
  --allow-no-sex \
  --silent \
  --out "${pairphase_LD}"

# Make a new bed-bim-fam file-set w/o the variants in LD
# using the list of variants in LD created in the previous step

"${plink}" \
  --bfile "${source_dataset}" \
  --exclude "${pairphase_LD}.prune.out" \
  --allow-no-sex \
  --make-bed \
  --silent \
  --out "${LD_pruned_dataset}"

# Progress report
echo "Done"
date
