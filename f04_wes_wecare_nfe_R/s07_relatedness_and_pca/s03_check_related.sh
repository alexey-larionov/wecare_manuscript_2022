#!/bin/bash

# s03_check_related.sh
# Calculate KING coefcient and remove relatives
# Alexey Larionov, 31Jan2021

# Intended use:
# ./s03_check_related.sh &> s03_check_related.log

# References
# http://www.cog-genomics.org/plink/2.0/distance#make_king
# https://www.cog-genomics.org/plink/2.0/formats#kin0

# Notes:

# Expected KING coefficients for relatives
# 0.5 (2^-1) Duplicates (identical tweens)
# 0.25 (2^-2) First-degree relatives (parent-child, full siblings)
# 0.125 (2^-3) 2-nd degree relatives (example?)
# 0.0625 (2^-4) 3-rd degree relatives (example?)

#0.5		Identical: duplicate samples and monozygotic tweens
#	0.353553391
#0.25		1st degree: parent child, full sibling
#	0.176776695
#0.125		2nd degree: some sort of cousines?
#	0.088388348
#0.0625		3rd degree: a large number of 1KGP NFE somehow falls in this category
#	0.044194174
#0.03125		Effectively unrelated

# Cutoff 0.0441941738241592=1/2^-4.5 was used in Preve 2020 to exclude all up to 3rd degree.
# Using Preve's cut-off would identify many (tens) related pairs in NFE, even suggesting somehow
# extended families of distantly related people, which is obviously wrong.
# Notably, the number of "related" samples, passed the Preve 2020 threshold, in WECARE increased
# when the more "common" (?) variants were selected for WECARE-NFE analysis.
# Again, this indivcated that the Preve threshold looks questionable.

# So the 0.088388348 cutoff was used here, as in some other places:
# https://people.virginia.edu/~wc9c/KING/manual.html
# https://www.biostars.org/p/434832/
# publications - REFS - for 0.088388348 ?

# There could be a confusion about the scaling of kinshio coefficient:
# somehow it may assume 0.5 as identity, not 1.  In future it would be
# useful to look what this script would report for duplicated samples.  

# The log says
# 0 variants handled by initial scan (18628 remaining).
# What is meant by "handled"? rare variants ??

# Stop at runtime errors
set -e

# Start message
echo "Detect and remove related cases (if any) using KING coefficient"
date
echo ""

# Folders
base_folder="/Users/alexey/Documents"
project_folder="${base_folder}/wecare/final_analysis_2021/reanalysis_wo_danish_2021/s02_wes_wecare_nfe"

scripts_folder="${project_folder}/scripts/s07_relatedness_and_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s07_relatedness_and_pca"
source_folder="${data_folder}/s02_bed_bim_fam"
output_folder="${data_folder}/s03_non_related"
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
--king-table-filter 0.088388348 \
--make-bed \
--king-cutoff 0.088388348 \
--silent \
--out "${output_fileset}"

# Completion message
echo "Done"
date
