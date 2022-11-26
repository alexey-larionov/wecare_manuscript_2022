#!/bin/bash

# s03_bsfstat.sh
# Started: Alexey Larionov, 06Aug2018
# Last updated: Alexey Larionov, 17Mar2019

# Use:
# sbatch s03_bsfstat.sh

# Calculate and plot bcf-stats

# Note loading of texlive module!

# Takes <1min

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s03_bsfstat
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=s03_bsfstat.log
#SBATCH --ntasks=2
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
echo "Calculate and plot bcf-stats for raw VCF"
date
echo ""

# Folders 
scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"

vcf_folder="${data_folder}/s10_raw_vcf"
stats_folder="${vcf_folder}/bcf_stats"

rm -fr "${stats_folder}" # remove results folder, if existed
mkdir -p "${stats_folder}"

# Files
vcf="${vcf_folder}/ampliseq_nfe_locID_MAflag.vcf"
stats="${stats_folder}/ampliseq_nfe_locID_MAflag.stats"

# Tools 
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.8/bin/bcftools"
plot_vcfstats="${tools_folder}/bcftools/bcftools-1.8/bin/plot-vcfstats"

# Progress report
echo "--- Files and folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "vcf: ${vcf}"
echo "stats_folder: ${stats_folder}"
echo "stats: ${stats}"
echo ""
echo "--- Tools ---"
echo ""
echo "bcftools: ${bcftools}"
echo "plot_vcfstats: ${plot_vcfstats}"
echo ""
echo ""

# Calculate vcf stats
echo "Calculating stats..."
"${bcftools}" stats "${vcf}" > "${stats}" 

# Options to explore:
# -R "${targets_bed}" -R or -T options to focus stats on targets ?? 
# -F "${ref_genome}" does not like FAI ...
# -d 0,1000,100 does not change much ...

# Plot the stats (plotting not ran for now, can run script manually and it works!)
echo "Making plots..."
"${plot_vcfstats}" "${stats}" -p "${stats_folder}"
echo ""

# Completion message
echo "Done"
date
echo ""
