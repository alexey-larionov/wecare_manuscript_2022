#!/bin/bash

# s03_bqsr_tables_before.sh
# Started: Alexey Larionov, 29Jun2018
# Last updated: Alexey Larionov, 16Feb2019

# Use:
# sbatch s03_bqsr_tables_before.sh

# This script launches analysis in batches of 25 BAMs per batch.   
# Assuming that gatk will use single thread per analysis and up to 6GB memory per thread, 
# batches of 25 would match the capacity of a single node on cluster (32 cores & 192 GB RAM per node)

# Takes ~3hrs

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J bqsr_tables_before
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=05:00:00
#SBATCH --output=s03_bqsr_tables_before.log
#SBATCH --exclusive

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
echo "Make BQSR tables before recalibration (in batches)"
date
echo ""

# Folders 
scripts_folder="$( pwd -P )"
base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
idrl_bam_folder="${data_folder}/s08_preprocessed_bam/idrl_bam"
bqsr_bam_folder="${data_folder}/s08_preprocessed_bam/idrl_bqsr_bam"

rm -fr "${bqsr_bam_folder}" # remove tables folder, if existed
mkdir -p "${bqsr_bam_folder}"

# Tools 
tools_folder="${base_folder}/tools"
java7="${tools_folder}/java/jre1.7.0_76/bin/java"
gatk="${tools_folder}/gatk/gatk-3.4-46/GenomeAnalysisTK.jar"

# Resources 

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"
dbsnp="${resources_folder}/gatk_bundle/b37/decompressed/dbsnp_138.b37.vcf"
indels_1k="${resources_folder}/gatk_bundle/b37/decompressed/1000G_phase1.indels.b37.vcf"
indels_mills="${resources_folder}/gatk_bundle/b37/decompressed/Mills_and_1000G_gold_standard.indels.b37.vcf"

targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Progress report
echo "--- Folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "idrl_bam_folder: ${idrl_bam_folder}"
echo "bqsr_bam_folder: ${bqsr_bam_folder}"
echo ""
echo "--- Tools ---"
echo ""
echo "java7: ${java7}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo "dbsnp: ${dbsnp}"
echo "indels_1k: ${indels_1k}"
echo "indels_mills: ${indels_mills}"
echo ""
echo "targets_interval_list: ${targets_interval_list}"
echo ""

# Batches 

# Make list of source bam files 
cd "${idrl_bam_folder}"
idrl_bam_files=$(ls *_fixmate_sort_rg_idrl.bam)

# Make list of samples 
samples=$(sed -e 's/_fixmate_sort_rg_idrl.bam//g' <<< "${idrl_bam_files}")
echo "Detected $(wc -w <<< ${samples}) bam files in the source folder"

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
    idrl_bam="${idrl_bam_folder}/${sample}_fixmate_sort_rg_idrl.bam"
    bqsr_table_before="${bqsr_bam_folder}/${sample}_before.txt"
    bqsr_table_before_log="${bqsr_bam_folder}/${sample}_before.log"

    # Process sample
    "${java7}" -Xmx6g -jar "${gatk}" \
      -T BaseRecalibrator \
      -R "${ref_genome}" \
      -L "${targets_interval_list}" -ip 10 \
      -knownSites "${dbsnp}" \
      -knownSites "${indels_1k}" \
      -knownSites "${indels_mills}" \
      -I "${idrl_bam}" \
      -o "${bqsr_table_before}" \
      &> "${bqsr_table_before_log}" &
          
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
