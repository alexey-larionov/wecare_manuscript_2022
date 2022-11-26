#!/bin/bash

# s02_add_LocID_and_MAflag.sh
# Started: Alexey Larionov, 16Mar2019
# Last updated: Alexey Larionov, 18Mar2019

# Use:
# sbatch s02_add_LocID_and_MAflag.sh

# Add location ID and Multi-Allelic flag

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_add_LocID_and_MAflag
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_add_LocID_and_MAflag.log
#SBATCH --ntasks=4
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4 
module load texlive # required to make summary pdf

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Allocated node: $(hostname)"
echo "Time: $(date)"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo "------------------ Output ------------------"
echo ""

# ---------------------------------------- #
#                    job                   #
# ---------------------------------------- #

# Stop at runtime errors
set -e

# Start message
echo "Add location ID and Multi-Allelic flag"
date
echo ""

# Folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

vcf_folder="${data_folder}/s10_raw_vcf"
tmp_folder="${vcf_folder}/tmp"

rm -fr "${tmp_folder}" # remove results folder, if existed
mkdir -p "${tmp_folder}"

# Files
raw_vcf_gz="${vcf_folder}/ampliseq_nfe_raw.vcf.gz"
raw_vcf="${tmp_folder}/ampliseq_nfe_raw.vcf"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "raw_vcf_gz: ${raw_vcf_gz}"
echo "tmp_folder: ${tmp_folder}"
echo ""
echo "--- Tools ---"
echo ""
echo "java: ${java}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "targets_interval_list: ${targets_interval_list}"
echo ""

# Unzip raw VCF
gunzip -c "${raw_vcf_gz}" > "${raw_vcf}"

# --- Add locations IDs to INFO field --- #
# To simplyfy tracing variants locations at later steps

# Progress report
echo "Adding locations IDs to INFO field ..."

# File name
locID_vcf="${tmp_folder}/ampliseq_nfe_locID.vcf"

# Compile names for temporary files
lid_tmp1=$(mktemp --tmpdir="${tmp_folder}" "lid_tmp1".XXXXXX)
lid_tmp2=$(mktemp --tmpdir="${tmp_folder}" "lid_tmp2".XXXXXX)
lid_tmp3=$(mktemp --tmpdir="${tmp_folder}" "lid_tmp3".XXXXXX)
lid_tmp4=$(mktemp --tmpdir="${tmp_folder}" "lid_tmp4".XXXXXX)

# Prepare data witout header
grep -v "^#" "${raw_vcf}" > "${lid_tmp1}"
awk '{printf("LocID=Loc%09d\t%s\n", NR, $0)}' "${lid_tmp1}" > "${lid_tmp2}"
awk 'BEGIN {OFS="\t"} ; { $9 = $9";"$1 ; print}' "${lid_tmp2}" > "${lid_tmp3}"
cut -f2- "${lid_tmp3}" > "${lid_tmp4}"

# Prepare header
grep "^##" "${raw_vcf}" > "${locID_vcf}"
echo '##INFO=<ID=LocID,Number=1,Type=String,Description="Location ID">' >> "${locID_vcf}"
grep "^#CHROM" "${raw_vcf}" >> "${locID_vcf}"

# Append data to header in the output file
cat "${lid_tmp4}" >> "${locID_vcf}"

# --- Make mask for multiallelic variants --- #

# Progress report
echo "Making mask for multiallelic variants..."

# File names
MAmask_vcf="${tmp_folder}/ampliseq_nfe_locID_MAmask.vcf"
MAmask_log="${tmp_folder}/ampliseq_nfe_locID_MAmask.log"

# Make mask
"${java}" -Xmx24g -jar "${gatk}" \
  -T SelectVariants \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${locID_vcf}" \
  -o "${MAmask_vcf}" \
  -restrictAllelesTo MULTIALLELIC \
  --downsampling_type NONE \
  -nt 4 &>  "${MAmask_log}"

# --- Add flag for multiallelic variants --- #

# Progress report
echo "Adding flag for multiallelic variants"

# File names
MAflag_vcf="${vcf_folder}/ampliseq_nfe_locID_MAflag.vcf"
MAflag_log="${tmp_folder}/ampliseq_nfe_locID_MAflag.log"

# Add flag
"${java}" -Xmx24g -jar "${gatk}" \
  -T VariantAnnotator \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${locID_vcf}" \
  -comp:MultiAllelic "${MAmask_vcf}" \
  -o "${MAflag_vcf}" \
  --downsampling_type NONE \
  -nt 4 &>  "${MAflag_log}"

# Completion message
echo "Done"
date
echo ""
