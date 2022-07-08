#!/bin/bash

# s02_clean_bam.sh
# Started: Alexey Larionov, modifyed from script of 2016
# Last updated: Alexey Larionov, 14Feb2019

# Fix-mate, sort, add RG, index and validate raw bam
# using settings fully equivalent to NFE analysis  
# to maximise compartinbility in the downstream analysis

# NFE settings were taken from 1kgenomes logs and 
# wes pipeline 02.16

# This script is called from another script on already allocated compute node,
# so there is no need for sbatch

# 30 copies of this script is launched in parallel to process 30 BAMs per batch 
# Assuming that picard uses single thread per analysis and it is explicitly limited 
# by up to 6GB memory per thread, this would fit to the capacity of a single 
# node on cluster (32 cores & 192 GB RAM per node) 

# Stop at runtime errors
set -e

# Start message
echo "Fix-mate, sort, add RG, index and validate raw bam"
date
echo ""

# Read parameters
sample="${1}"
raw_bam_folder="${2}"
clean_bam_folder="${3}"
samtools="${4}"
java6="${5}"
picard="${6}"
library="${7}"
platform="${8}"
flowcell="${9}"

######################################

# Example of expected parameters:

#sample="103_S147_L007"
#raw_bam_folder="/rds/project/erf33/rds-erf33-medgen/users/alexey/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results/s05_bams/bam"
#clean_bam_folder="/rds/project/erf33/rds-erf33-medgen/users/alexey/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results/s06_clean_bams/bam"
#samtools="/rds/project/erf33/rds-erf33-medgen/tools/"
#java6="/rds/project/erf33/rds-erf33-medgen/tools/"
#picard="/rds/project/erf33/rds-erf33-medgen/tools/"
#library="wecare_ampliseq_01"
#platform="illumina"
#flowcell="HVMMTBBXX"

######################################

# Progress report
echo "sample: ${sample}"
echo ""
echo "raw_bam_folder: ${raw_bam_folder}"
echo "clean_bam_folder: ${clean_bam_folder}"
echo ""
echo "samtools: ${samtools}"
echo "java6: ${java6}"
echo "picard: ${picard}"
echo ""
echo "library: ${library}"
echo "platform: ${platform}"
echo "flowcell: ${flowcell}"
echo ""

# Parce the sample name (lane_no is used in RG group)
IFS="_" read sample_no illumina_id lane_no <<< ${sample}

# Progress report
echo "Cleaning BAM for sample ${sample}"
echo "$(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------- Sort by name ------- #

# Progress report
echo "Started sorting by name (required by fixmate)"

# Sorted bam file name
raw_bam="${raw_bam_folder}/${sample}_raw.bam"
nsort_bam="${clean_bam_folder}/${sample}_nsort.bam"

# Sort using samtools (later may be switched to picard SortSam)
"${samtools}" sort -n -o "${nsort_bam}" -T "${nsort_bam/_nsort.bam/_nsort_tmp}_${RANDOM}" "${raw_bam}"

# Progress report
echo "Completed sorting by name: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------- Fixmate ------- #

# Progress report
echo "Started fixing mate-pairs"

# Fixmated bam file name  
fixmate_bam="${clean_bam_folder}/${sample}_fixmate.bam"
  
# Fixmate (later may be switched to Picard FixMateInformation)
"${samtools}" fixmate "${nsort_bam}" "${fixmate_bam}"

# Remove nsorted bam
rm -f "${nsort_bam}"

# Progress report
echo "Completed fixing mate-pairs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------- Sort by coordinate ------- #

# Progress report
echo "Started sorting by coordinate"

# Sorted bam file name
sort_bam="${clean_bam_folder}/${sample}_fixmate_sort.bam"

# Sort using samtools (later may be switched to picard SortSam)
"${samtools}" sort -o "${sort_bam}" -T "${sort_bam/_sort.bam/_sort_tmp}_${RANDOM}" "${fixmate_bam}"

# Remove fixmated bam
rm -f "${fixmate_bam}"

# Progress report
echo "Completed sorting by coordinate: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------- Add RG and index ------- #

# Progress report
echo "Started adding read group information"

# File name for bam with RGs
rg_bam_file="${sample}_fixmate_sort_rg.bam"
rg_bam="${clean_bam_folder}/${rg_bam_file}"

# Add read groups
"${java6}" -Xmx6g -jar "${picard}" AddOrReplaceReadGroups \
  INPUT="${sort_bam}" \
  OUTPUT="${rg_bam}" \
  RGID="${sample}_${library}" \
  RGLB="${library}" \
  RGPL="${platform}" \
  RGPU="${flowcell}_${lane_no}" \
  RGSM="${sample}" \
  VERBOSITY=ERROR \
  CREATE_INDEX=true \
  QUIET=true

# Remove bam without RG
rm -f "${sort_bam}"

# Progress report
echo "Completed indexing and adding read group information: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------- Validate bam ------- #
# Prints output to the sample clean-up log
# exits if errors found (prints initial 100 errors by default)
# Later a separate script checks each clean-up log to make sure that 
# all cleaned BAM files have passed the validation 

# Progress report
echo "Started bam validation"

# Validate bam
"${java6}" -Xmx6g -jar "${picard}" ValidateSamFile \
  INPUT="${rg_bam}"
#  MODE=SUMMARY

# Progress report
echo "Completed bam validation: $(date +%H:%M:%S)"
echo ""

# Completion message
echo "Done all tasks"
date
echo ""
