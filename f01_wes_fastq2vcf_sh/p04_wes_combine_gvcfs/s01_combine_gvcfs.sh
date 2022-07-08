#!/bin/bash

# s01_combine_gvcfs.sh
# Combine gvcfs
# Alexey Larionov, 14Sep2016

# Stop at any error
set -e

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_combine_gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a01_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${combined_gvcfs_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

# Initialise file for list of source gvcfs
source_gvcfs="${set_id}.list"
> "${source_gvcfs}"

# Suspend stopping at errors
set +e

# For each library
for library in ${libraries}
do

  # Progress report
  echo "${library}"
  echo "Getting list of samples"
  
  # Copy samples file
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/samples.txt" "${combined_gvcfs_folder}/${set_id}_source_files/${library}_samples.txt" 
  exit_code="${?}"
  
  # Stop if copying failed
  if [ "${exit_code}" != "0" ] 
  then
    echo ""
    echo "Failed getting source data from NAS"
    echo "Script terminated"
    echo ""
    exit
  fi

  # Progress report
  echo "Copying gvcfs to cluster"

  # Get list of samples
  samples=$(awk 'NR>1 {print $1}' "${combined_gvcfs_folder}/${set_id}_source_files/${library}_samples.txt")

  # For each sample
  for sample in ${samples}
  do

    # Copy gvcf file and index
    gvcf_file=$(awk -v sm="${sample}" '$1==sm {print $2}' "${combined_gvcfs_folder}/${set_id}_source_files/${library}_samples.txt")
    
    rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/${gvcf_file}" "${combined_gvcfs_folder}/${set_id}_source_files/"
    exit_code_1="${?}"
    
    rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/${gvcf_file}.idx" "${combined_gvcfs_folder}/${set_id}_source_files/"
    exit_code_2="${?}"
  
    # Stop if copying failed
    if [ "${exit_code_1}" != "0" ] || [ "${exit_code_2}" != "0" ]  
    then
        echo ""
        echo "Failed getting source data from NAS"
        echo "Script terminated"
        echo ""
        exit
    fi
    
    # Add gvcf file name to the list of source gvcfs
    echo "${combined_gvcfs_folder}/${set_id}_source_files/${gvcf_file}" >> "${source_gvcfs}"
    
    # Progress report
    echo "${sample}"
    
  done # next sample
  
  echo ""
  
done # next library

# Restore stopping at errors
set -e

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Combine gvcfs --- #

# Progress report
echo "Started combining gvcfs"

# File names
combined_gvcf="${set_id}.g.vcf"
combining_gvcf_log="${set_id}_combine_gvcfs.log"
combined_gvcf_md5="${combined_gvcf}.md5"

# Process files  
"${java}" -Xmx60g -jar "${gatk}" \
  -T CombineGVCFs \
	-R "${ref_genome}" \
	-V "${source_gvcfs}" \
  -o "${combined_gvcf}" \
  2> "${combining_gvcf_log}"

# Notes:

# Removed
#   -L "${targets_intervals}" -ip 10 \

# -V argument takes a file with list of gvcfs as the argument 

# No papallelism supported in Oct 2015
# http://gatkforums.broadinstitute.org/discussion/3973/combinegvcfs-performance mentions use of -nt
# However, runs with -nt or -nct generated errors (...CombineGVCFs currently does not support parallel execution...)  

# Progress report
echo "Completed combining gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Make md5 file
echo "Started calculating md5 sum"
md5sum "${combined_gvcf}" "${combined_gvcf}.idx" > "${combined_gvcf_md5}"

# Progress report
echo "Completed calculating md5 sum: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ----- Remove source gvcf files from hpc ----- #

rm -fr "${combined_gvcfs_folder}/${set_id}_source_files/"

echo "Source files are removed from cluster"
echo ""

# ----- Copy results to NAS ----- #

echo "Started copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Suspend stopping at errors
set +e

# Copy results
ssh -x "${data_server}" "mkdir -p ${project_location}/${project}/combined_gvcfs"

rsync -thrqe "ssh -x" "${combined_gvcf}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_1="${?}"
rsync -thrqe "ssh -x" "${combined_gvcf}.idx" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_2="${?}"
rsync -thrqe "ssh -x" "${combined_gvcf_md5}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_3="${?}"
rsync -thrqe "ssh -x" "${combining_gvcf_log}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_4="${?}"
rsync -thrqe "ssh -x" "${source_gvcfs}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_5="${?}"
rsync -thrqe "ssh -x" "${set_id}.log" "${data_server}:${project_location}/${project}/combined_gvcfs/"
exit_code_6="${?}"

# Stop if copying failed
if [ "${exit_code_1}" != "0" ] || \
   [ "${exit_code_2}" != "0" ] || \
   [ "${exit_code_3}" != "0" ] || \
   [ "${exit_code_4}" != "0" ] || \
   [ "${exit_code_5}" != "0" ] || \
   [ "${exit_code_6}" != "0" ]
then
  echo ""
  echo "Failed copying results to NAS"
  echo "Script terminated"
  echo ""
  exit
fi

# Restore stopping at errors
set -e

# Progress report to log on nas
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"

# Progress report
echo "Completed copying results to NAS: ${timestamp}"
echo ""

# ----- Remove bulk results from cluster ----- #

rm -f "${combined_gvcf}"
rm -f "${combined_gvcf}.idx"
rm -f "${combined_gvcf_md5}"
#rm -f "${combining_gvcf_log}"
#rm -f "${source_gvcfs}"
#rm -f "${set_id}.log"

# Progress report to log on nas
ssh -x "${data_server}" "echo \"Bulk results have been removed from cluster\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"

# Progress report
echo "Bulk results have been removed from cluster"
echo ""

# --- Return to the initial folder --- #

cd "${init_dir}"
