#!/bin/bash

# s02_get_wes_vqsr_for_panel.sh
# Started: Alexey Larionov, 15Mar2019
# Last updated: Alexey Larionov, 15Mar2019

# Use:
# sbatch s02_get_wes_vqsr_for_panel.sh

# Get data for Ampliseq panel from WES VQSR VCF for comparison

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s02_get_wes_vqsr_for_panel
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s02_get_wes_vqsr_for_panel.log
#SBATCH --ntasks=4
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4 

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
echo "Get data for Ampliseq panel from WES VQSR VCF for comparison"
date
echo ""

# Folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
wes_panel_vcf="${data_folder}/s11_vqsr_vcf/wes_nfe_panel_vqsr.vcf"
gatk_log="${data_folder}/s11_vqsr_vcf/wes_nfe_panel_vqsr.log"

# Sourse file
source_server="admin@mgqnap.medschl.cam.ac.uk"
source_folder="/share/wecare_data/wes05_nov2016/wecare_nfe_nov2016_vqsr"
source_vcf="wecare_nfe_nov2016_vqsr.vcf"

# Tools
tools_folder="${base_folder}/tools"
java="${tools_folder}/java/jre1.8.0_40/bin/java"
gatk="${tools_folder}/gatk/gatk-3.6-0/GenomeAnalysisTK.jar"

# Resources 
targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "source_server: ${source_server}"
echo "source_folder: ${source_folder}"
echo "source_vcf: ${source_vcf}"
echo "wes_panel_vcf: ${wes_panel_vcf}"
echo "gatk_log: ${gatk_log}"
echo ""
echo "--- Tools ---"
echo ""
echo "gatk: ${gatk}"
echo "java: ${java}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "targets_interval_list: ${targets_interval_list}"
echo ""

# --- Copy source file from NAS --- #

# Progress report
echo "Copying source files ..."

# Suppress stopping at errors
set +e

rsync -thrqe "ssh -x" "${source_server}:${source_folder}/${source_vcf}" "${data_folder}/s11_vqsr_vcf/"
exit_code="${?}"

# Stop if copying failed
if [ "${exit_code}" != "0" ]  
then
  echo ""
  echo "Failed to copy source file from NAS"
  echo "Script terminated"
  echo ""
  exit
fi

rsync -thrqe "ssh -x" "${source_server}:${source_folder}/${source_vcf}.idx" "${data_folder}/s11_vqsr_vcf/"
exit_code="${?}"

# Stop if copying failed
if [ "${exit_code}" != "0" ]  
then
  echo ""
  echo "Failed to copy index file from NAS"
  echo "Script terminated"
  echo ""
  exit
fi

# Resume stopping at errors
set -e

# Progress report
echo "Done"
echo ""

# --- Select data for the panel --- #

echo "Extracting panel regions ..."

"${java}" -Xmx24g -jar "${gatk}" \
  -T SelectVariants \
  -R "${ref_genome}" \
  -L "${targets_interval_list}" -ip 10 \
  -V "${data_folder}/s11_vqsr_vcf/${source_vcf}" \
  -o "${wes_panel_vcf}" \
  -nt 4 &>  "${gatk_log}"

# Clean up
#rm "${data_folder}/s11_vqsr_vcf/${source_vcf}" "${data_folder}/s11_vqsr_vcf/${source_vcf}.idx"

# Progress report
echo "Done"
echo ""
echo "Done all tasks"
date
echo ""
