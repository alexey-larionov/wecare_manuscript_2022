#!/bin/bash

# s02_indel_realignment.sh
# Started: Alexey Larionov, 14Feb2019
# Last updated: Alexey Larionov, 15Feb2019

# Use:
# sbatch s02_indel_realignment.sh

# The script copies settings from WES-02.16 pipeline, 
# which was used for 1k-genomes and WECARE-WES datasets, 
# for compartibility in the downstream analysis 

# The script limits analysis and output to 100 bases around the panel targets  

# This script launches analysis in batches of 25 BAMs per batch.   
# Assuming that gatk will use single thread per analysis (no -nt ot -ntc option) and up to 6GB memory per thread, 
# batches of 25 would match the capacity of a single node on cluster (32 cores & 192 GB RAM per node)

# Takes ~3hr

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J indel_realignment
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=05:00:00
#SBATCH --output=s02_indel_realignment.log
#SBATCH --exclusive
##SBATCH --qos=INTR

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
echo "Perform local INDEL realignment (in batches)"

date
echo ""

# Folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
clean_bam_folder="${data_folder}/s06_clean_bam/bam"
idrl_bam_folder="${data_folder}/s08_preprocessed_bam/idrl_bam" # already contains idrl targets

# Tools 
tools_folder="${base_folder}/tools"
java7="${tools_folder}/java/jre1.7.0_76/bin/java"
gatk="${tools_folder}/gatk/gatk-3.4-46/GenomeAnalysisTK.jar"

# Resources 
resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
indels_1k="${resources_folder}/gatk_bundle/b37/decompressed/1000G_phase1.indels.b37.vcf"
indels_mills="${resources_folder}/gatk_bundle/b37/decompressed/Mills_and_1000G_gold_standard.indels.b37.vcf"

targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Progress report
echo "--- Folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "clean_bam_folder: ${clean_bam_folder}"
echo "idrl_bam_folder: ${idrl_bam_folder}"
echo ""
echo "--- Tools ---"
echo ""
echo "java7: ${java7}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "indels_1k: ${indels_1k}"
echo "indels_mills: ${indels_mills}"
echo ""
echo "targets_interval_list: ${targets_interval_list}"
echo ""

# Batches 

# Make list of source bam files 
cd "${clean_bam_folder}"
clean_bam_files=$(ls *_fixmate_sort_rg.bam)

# Make list of samples 
samples=$(sed -e 's/_fixmate_sort_rg.bam//g' <<< "${clean_bam_files}")
echo "Detected $(wc -w <<< ${samples}) bam files in the source folder"

#samples="103_S147_L007"
#samples="108_S482_L008"

# Make batches of 25 samples each (store temporary files in tmp folder)
tmp_folder="${data_folder}/s08_preprocessed_bam/tmp"
rm -fr "${tmp_folder}" # remove temporary folder, if existed
mkdir -p "${tmp_folder}"
cd "${tmp_folder}"
split -l 25 <<< "${samples}"
batches=$(ls)

# Progress report
echo "Made "$(wc -w <<< $batches)" batches of up to 25 samples each"
echo ""

# --- Analysis --- #

# Initialise batch counter
batch_no=0

# For each batch
for batch in ${batches}
do
  
  # Get list of samples in the batch
  samples=$(cat $batch)

  # For each sample in the batch
  for sample in ${samples}
  do  
  
    # Compile file names
    clean_bam="${clean_bam_folder}/${sample}_fixmate_sort_rg.bam"
    idrl_targets="${idrl_bam_folder}/${sample}_idrl_targets.intervals"
    idrl_bam="${idrl_bam_folder}/${sample}_fixmate_sort_rg_idrl.bam"
    idrl_log="${idrl_bam_folder}/${sample}_idrl.log"

    # Process sample
    "${java7}" -Xmx6g -jar "${gatk}" \
      -T IndelRealigner \
      -R "${ref_genome}" \
      -L "${targets_interval_list}" -ip 100 \
      -targetIntervals "${idrl_targets}" \
      -known "${indels_1k}" \
      -known "${indels_mills}" \
      -I "${clean_bam}" \
      -o "${idrl_bam}" \
      &> "${idrl_log}" &
      
  done # start next sample in the batch
  
  # Whait until the batch (all background processes) completed
  wait
  
  # Progress report
  batch_no=$(( $batch_no + 1 ))
  echo "$(date +%H:%M:%S) Done batch ${batch_no}"
  
done # next batch

# Remove temporary files
cd "${scripts_folder}"
rm -fr "${tmp_folder}"

# Completion message
echo ""
echo "Done all tasks"
date
echo ""
