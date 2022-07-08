reference_sequence=
/scratch/medgen/resources/gatk_bundle/b37/decompressed/human_g1k_v37.fasta
/rds/project/erf33/rds-erf33-medgen/resources/gatk_bundle/b37/decompressed/human_g1k_v37.fasta


grep -P "4\t57273790" --color=auto set2.g.vcf

grep reference --color=auto set1.g.vcf

$samtools faidx $ref_genome 4:57273790-57273790
