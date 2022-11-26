#!/bin/bash

# s01_make_gvcfs.sh
# Started: Alexey Larionov, 24Jul2018
# Last updated: Alexey Larionov, 18Feb2019

# Use:
# sbatch s01_make_gvcfs.sh

# This script launches analysis in batches of 30 BAMs per batch.   
# Allowing gatk to use 6GB memory per run, batches of 30 would match 
# the capacity of a single node on cluster (32 cores & 192 GB RAM per node)
# Excluding the soft-clipped bases from variant calling

# Takes up to ~5 hrs for analysis # 3
# Took more in analysis # 2 because of the larger number of spurious variants
# Should take even longer for analysis 4 because of the old slow GATK version

# ------------------------------------ #
#         sbatch instructions          #
# ------------------------------------ #

#SBATCH -J s01_make_gvcfs
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --output=s01_make_gvcfs.log
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
echo "Make individual gVCF files (in batches)"
date
echo ""

# Files and folders 

scripts_folder="$( pwd -P )"

base_folder="/rds/project/erf33/rds-erf33-medgen"
data_folder="${base_folder}/users/alexey/wecare/wecare_ampliseq/analysis4/ampliseq_nfe/data_and_results"
bam_folder="${data_folder}/s08_preprocessed_bam/idrl_bqsr_bam"
gvcf_folder="${data_folder}/s09_raw_vcf/gvcf"

rm -fr "${gvcf_folder}" # remove output folder, if existed
mkdir -p "${gvcf_folder}"

# Tools 
tools_folder="${base_folder}/tools"
java7="${tools_folder}/java/jre1.7.0_76/bin/java"
gatk="${tools_folder}/gatk/gatk-3.4-46/GenomeAnalysisTK.jar"

# Resources 

resources_folder="${base_folder}/resources"
ref_genome="${resources_folder}/gatk_bundle/b37/decompressed/human_g1k_v37.fasta"

targets_interval_list="${data_folder}/s00_targets/ampliseq_targets_b37.interval_list"

# Progress report
echo "--- Folders ---"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "bam_folder: ${bam_folder}"
echo "gvcf_folder: ${gvcf_folder}"
echo ""
echo "--- Tools ---"
echo ""
echo "java7: ${java7}"
echo "gatk: ${gatk}"
echo ""
echo "--- Resources ---"
echo ""
echo "ref_genome: ${ref_genome}"
echo ""
echo "targets_interval_list: ${targets_interval_list}"
echo ""

# Batches 

# Make list of source bam files 
# note sorting by size: -S to get files of similar size into batches
cd "${bam_folder}"
bam_files=$(ls -S *_fixmate_sort_rg_idrl_bqsr.bam)

# Make list of samples 
samples=$(sed -e 's/_fixmate_sort_rg_idrl_bqsr.bam//g' <<< "${bam_files}")
echo "Detected $(wc -w <<< ${samples}) bam files in the source folder"

# Make batches of 30 samples each (store batch files in tmp folder)
tmp_folder="${gvcf_folder}/tmp"
rm -fr "${tmp_folder}" # remove temporary folder, if existed
mkdir -p "${tmp_folder}"
cd "${tmp_folder}"
split -l 30 <<< "${samples}"
batches=$(ls)

# Progress report
echo "Made "$(wc -w <<< $batches)" batches of up to 30 samples each"
echo ""

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
    bam="${bam_folder}/${sample}_fixmate_sort_rg_idrl_bqsr.bam"
    gvcf="${gvcf_folder}/${sample}.g.vcf.gz"
    gvcf_log="${gvcf_folder}/${sample}.log"

    # Run HaplotypeCaller in GVCF mode
    "${java7}" -Xmx6g -jar "${gatk}" \
      -T HaplotypeCaller \
      -R "${ref_genome}" \
      -L "${targets_interval_list}" -ip 10 \
      -I "${bam}" \
      -o "${gvcf}" \
      -ERC GVCF \
      --dontUseSoftClippedBases \
      --downsampling_type NONE \
      &> "${gvcf_log}" &
    
      # --dont-use-soft-clipped-bases to reduce false-calls 
      # Suppress down-sampling - assuming PCR may give random proportions of alleles ...
      # should a somatic tool be better for ampliseq with DP 10 and AF 20 ?? 
      
  done # next sample in the batch
  
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
