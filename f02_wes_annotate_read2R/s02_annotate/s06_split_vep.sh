#!/bin/bash

# s06_split_vep.sh
# Alexey Larionov, 10Sep2020

#SBATCH -J s06_split_vep
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s06_split_vep.log
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Allocated node: $(hostname)"
echo "$(date)"
echo ""
echo "Job name: ${SLURM_JOB_NAME}"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo " ------------------ Job progress ------------------ "
echo ""

# Stop at runtime errors
set -e

# Start message
echo "Started s06_split_vep: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s02_annotate"
scripts_folder="${project_folder}/scripts/s02_annotate"
cd "${scripts_folder}"

# Files
source_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep.vcf.gz"
split_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep_split.vcf.gz"
split_log="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep_split.log"
rm_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep_split_rm.vcf.gz"
rm_log="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep_split_rm.log"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# Num of threads
n_threads="4"

# Progress report
echo "--- Settings ---"
echo ""
echo "source_vcf: ${source_vcf}"
echo "split_vcf: ${split_vcf}"
echo "rm_vcf: ${rm_vcf}"
echo ""

# Split vcf:
# Fields could be String (default), Integer or Float
# Note lack of spaces in the list of fields !

echo "Splitting VEP field ..."
"${bcftools}" +split-vep "${source_vcf}" \
--columns \
Allele:String,\
Consequence:String,\
IMPACT:String,\
SYMBOL:String,\
Gene:String,\
Feature_type:String,\
Feature:String,\
BIOTYPE:String,\
EXON:String,\
INTRON:String,\
HGVSc:String,\
HGVSp:String,\
cDNA_position:String,\
CDS_position:String,\
Protein_position:String,\
Amino_acids:String,\
Codons:String,\
Existing_variation:String,\
DISTANCE,\
STRAND,\
FLAGS,\
VARIANT_CLASS:String,\
SYMBOL_SOURCE:String,\
HGNC_ID,\
CANONICAL:String,\
MANE:String,\
TSL,\
APPRIS,\
CCDS:String,\
ENSP:String,\
SWISSPROT:String,\
TREMBL:String,\
UNIPARC:String,\
GENE_PHENO:String,\
NEAREST:String,\
SIFT:String,\
PolyPhen:String,\
DOMAINS:String,\
miRNA:String,\
HGVS_OFFSET,\
AF:Float,\
AFR_AF:Float,\
AMR_AF:Float,\
EAS_AF:Float,\
EUR_AF:Float,\
SAS_AF:Float,\
AA_AF:Float,\
EA_AF:Float,\
gnomAD_AF:Float,\
gnomAD_AFR_AF:Float,\
gnomAD_AMR_AF:Float,\
gnomAD_ASJ_AF:Float,\
gnomAD_EAS_AF:Float,\
gnomAD_FIN_AF:Float,\
gnomAD_NFE_AF:Float,\
gnomAD_OTH_AF:Float,\
gnomAD_SAS_AF:Float,\
MAX_AF:Float,\
MAX_AF_POPS:String,\
CLIN_SIG:String,\
SOMATIC:String,\
PHENO:String,\
PUBMED:String,\
VAR_SYNONYMS:String,\
MOTIF_NAME:String,\
MOTIF_POS,\
HIGH_INF_POS,\
MOTIF_SCORE_CHANGE,\
TRANSCRIPTION_FACTORS:String,\
CADD_PHRED:Float,\
CADD_RAW:Float \
--annot-prefix vep_ \
--output "${split_vcf}" \
--output-type z \
&> "${split_log}"

# Index split vcf
"${bcftools}" index "${split_vcf}"

echo "Removing unsplit CSQ column ..."
"${bcftools}" annotate "${split_vcf}"\
  --remove INFO/CSQ \
  --output "${rm_vcf}" \
  --output-type z \
  &> "${rm_log}"

# Index output VCF
"${bcftools}" index "${rm_vcf}"

# Summary of INFO fields
echo ""
echo "Number of INFO fields in split rm vep vcf:"
"${bcftools}" view -h "${rm_vcf}" | grep ^##INFO | wc -l
echo ""

echo "List of INFO fields in split rm vep vcf:"
"${bcftools}" view -h "${rm_vcf}" | grep ^##INFO
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""
