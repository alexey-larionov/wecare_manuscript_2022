#!/bin/bash

## s01_hard_filter_vcf.sb.sh
## Wes library: hard filtering vcf by DP and QUAL
## SLURM submission script
## Alexey Larionov, 08Sep2016
# AL08Oct208: updated pandoc version

#SBATCH -J hard_filter
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH -p sandybridge

##SBATCH --qos=INTR
##SBATCH --time=00:30:00
##SBATCH -A TISCHKOWITZ-SL3

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load default-impi

# Additional modules for knitr-rmarkdown (used for histograms)
module load gcc/5.2.0
module load boost/1.50.0
module load texlive/2015
module load pandoc/2.0.6

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo ""
echo "Job name: ${SLURM_JOB_NAME}"
echo "Allocated node: $(hostname)"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo " ------------------ Output ------------------ "
echo ""

## Read parameters
job_file="${1}"
scripts_folder="${2}"
log="${3}"

## Do the job
"${scripts_folder}/s01_hard_filter_vcf.sh" \
         "${job_file}" \
         "${scripts_folder}" &>> "${log}"
