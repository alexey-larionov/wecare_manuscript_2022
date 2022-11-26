#!/bin/bash

# s04_annotate_with_clinvar.sh
# Alexey Larionov, 09Sep2020

# Check consistency of chromosome naming in the data and ClinVar

#SBATCH -J s04_annotate_with_clinvar
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s04_annotate_with_clinvar.log
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
echo "Started s04_annotate_with_clinvar: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
clinvar_folder="${base_folder}/resources/clinvar/vcf_GRCh37/v20200905"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"
data_folder="${project_folder}/data/s02_annotate"
scripts_folder="${project_folder}/scripts/s02_annotate"
cd "${scripts_folder}"

# Tools
tools_folder="${base_folder}/tools"
bcftools="${tools_folder}/bcftools/bcftools-1.10.2/bin/bcftools"

# Files
source_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id.vcf.gz"
output_vcf="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar.vcf.gz"
clinvar_log="${data_folder}/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar.log"
clinvar_vcf="${clinvar_folder}/clinvar_20200905.vcf.gz"

# Progress report
echo "--- Input and output files ---"
echo ""
echo "source_vcf: ${source_vcf}"
echo "output_vcf: ${output_vcf}"
echo "clinvar_vcf: ${clinvar_vcf}"
echo ""
echo "Working..."

# Annotate using bcftools
"${bcftools}" annotate "${source_vcf}" \
  --annotations "${clinvar_vcf}" \
  --columns INFO \
  --output "${output_vcf}" \
  --output-type z \
  --threads 4 \
  &> "${clinvar_log}"

# Index output vcf
"${bcftools}" index "${output_vcf}"

# Summary of INFO fields

echo ""
echo "Number of INFO fields in source vcf:"
"${bcftools}" view -h "${source_vcf}" | grep ^##INFO | wc -l
echo ""

echo ""
echo "Number of INFO fields in ClinVar-annotated vcf:"
"${bcftools}" view -h "${output_vcf}" | grep ^##INFO | wc -l
echo ""

echo "List of INFO fields in ClinVar-annotated vcf:"
"${bcftools}" view -h "${output_vcf}" | grep ^##INFO
echo ""

# Progress report
echo ""
echo "selected lines from output_vcf:"
echo "" # print some lines by --query to extract fields from bcf/vcf into user-frienlty format #-i include #-f format
"${bcftools}" query \
  -i 'ALLELEID != "."' \
  -f '%ID\t%ALLELEID\t%CLNSIG\t%CLNDN\n' "${output_vcf}" | head
echo ""

# Completion message
echo "Done: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Description of the added ClinVar annotations --- #

##ID=<Description="ClinVar Variation ID">

##INFO=<ID=ALLELEID,Number=1,Type=Integer,Description="the ClinVar Allele ID">
##INFO=<ID=CLNREVSTAT,Number=.,Type=String,Description="ClinVar review status for the Variation ID">

##INFO=<ID=CLNSIG,Number=.,Type=String,Description="Clinical significance for this single variant">
##INFO=<ID=CLNDN,Number=.,Type=String,Description="ClinVar's preferred disease name for the concept specified by disease identifiers in CLNDISDB">
##INFO=<ID=CLNDISDB,Number=.,Type=String,Description="Tag-value pairs of disease database name and identifier, e.g. OMIM:NNNNNN">

##INFO=<ID=CLNSIGCONF,Number=.,Type=String,Description="Conflicting clinical significance for this single variant">
##INFO=<ID=SSR,Number=1,Type=Integer,Description="Variant Suspect Reason Codes. One or more of the following values may be added: 0 - unspecified, 1 - Paralog, 2 - byEST, 4 - oldAlign, 8 - Para_EST, 16 - 1kg_failed, 1024 - other">

##INFO=<ID=CLNVI,Number=.,Type=String,Description="the variant's clinical sources reported as tag-value pairs of database and variant identifier">
##INFO=<ID=ORIGIN,Number=.,Type=String,Description="Allele origin. One or more of the following values may be added: 0 - unknown; 1 - germline; 2 - somatic; 4 - inherited; 8 - paternal; 16 - maternal; 32 - de-novo; 64 - biparental; 128 - uniparental; 256 - not-tested; 512 - tested-inconclusive; 1073741824 - other">

##INFO=<ID=GENEINFO,Number=1,Type=String,Description="Gene(s) for the variant reported as gene symbol:gene id. The gene symbol and id are delimited by a colon (:) and each pair is delimited by a vertical bar (|)">
##INFO=<ID=CLNVCSO,Number=1,Type=String,Description="Sequence Ontology id for variant type">
##INFO=<ID=CLNVC,Number=1,Type=String,Description="Variant type">
##INFO=<ID=MC,Number=.,Type=String,Description="comma separated list of molecular consequence in the form of Sequence Ontology ID|molecular_consequence">

##INFO=<ID=RS,Number=.,Type=String,Description="dbSNP ID (i.e. rs number)">
##INFO=<ID=CLNHGVS,Number=.,Type=String,Description="Top-level (primary assembly, alt, or patch) HGVS expression.">
##INFO=<ID=DBVARID,Number=.,Type=String,Description="nsv accessions from dbVar for the variant">

##INFO=<ID=AF_ESP,Number=1,Type=Float,Description="allele frequencies from GO-ESP">
##INFO=<ID=AF_EXAC,Number=1,Type=Float,Description="allele frequencies from ExAC">
##INFO=<ID=AF_TGP,Number=1,Type=Float,Description="allele frequencies from TGP">

##INFO=<ID=CLNSIGINCL,Number=.,Type=String,Description="Clinical significance for a haplotype or genotype that includes this variant. Reported as pairs of VariationID:clinical significance.">
##INFO=<ID=CLNDNINCL,Number=.,Type=String,Description="For included Variant : ClinVar's preferred disease name for the concept specified by disease identifiers in CLNDISDB">
##INFO=<ID=CLNDISDBINCL,Number=.,Type=String,Description="For included Variant: Tag-value pairs of disease database name and identifier, e.g. OMIM:NNNNNN">
