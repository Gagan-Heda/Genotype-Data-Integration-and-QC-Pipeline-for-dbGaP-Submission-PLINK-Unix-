#!/bin/bash
#SBATCH -M teach 
#SBATCH -A hugen2071-2024f
#SBATCH --mem-per-cpu=100G
#SBATCH -t 4:00:00



set -v
set -euo pipefail
module load plink/1.90b6.7



#Defining the paths

input_file="/ix1/hugen2071-2024f/data/Project_2"
output_file="/ix1/hugen2071-2024f/data/scratch/$USER/project_2"


echo " PROJECT 2 PROCESSING STARTED"
echo "PROCESSING OF GENOTYPE_DATA File"


cut -f 2,5,6 "$input_file/GENOTYPE_DATA.bim" > bim_alleles.txt
cut -d ',' -f 3,4,5 "$input_file/manifest.csv" | tr ',' '\t' > manifest_alleles.txt
awk 'BEGIN {FS=OFS="\t"} NR==FNR {a[$1]=$2"\t"$3; next} $1 in a {print $1, a[$1], $2, $3}' bim_alleles.txt manifest_alleles.txt > allele_update.txt


echo "Updating the alleles"


plink --bfile "$input_file/GENOTYPE_DATA" \
--update-alleles allele_update.txt \
--make-bed \
--out $output_file/Updated_Genotype_data



echo "Updating Allleles successful" 
echo "Head of Updated_Genotype_data.fam"
head $output_file/Updated_Genotype_data.fam
echo "\n\nHead of Updated_Genotype_data.bim"
head $output_file/Updated_Genotype_data.bim



echo "Storing all the values ending with dup and then removing it"
awk '$2 ~ /dup$/ {print $1, $2}' "$output_file/Updated_Genotype_data.fam" > duplicate.txt



plink --bfile "$output_file/Updated_Genotype_data" \
--remove duplicate.txt \
--make-bed \
--out $output_file/GENOTYPE_UPDATE


echo "Checking for missingness"

#Checking for missingness

plink --bfile "$output_file/GENOTYPE_UPDATE" \
--missing \
--out $output_file/GENOTYPE_DATA



awk '$5 == 1 {print $1, $2}' $output_file/GENOTYPE_DATA.lmiss > markers_to_remove.txt
awk '$6 == 1 {print $1}' $output_file/GENOTYPE_DATA.imiss > samples_to_remove.txt


echo "Removing variants with MCR = 100%"

# Filter data to remove samples and markers with 100% missingness

plink --bfile "$output_file/GENOTYPE_UPDATE" \
--remove samples_to_remove.txt \
--exclude markers_to_remove.txt \
--make-bed \
--out $output_file/GENOTYPE_Removed


echo " Checking for sex discrepancies using --check-sex function"

# Check-sex

plink --bfile $output_file/GENOTYPE_Removed \
--check-sex 0.9 0.99 \
--out $output_file/Genotype_sex


echo "\n\nHead of Genotype_sex"
head $output_file/Genotype_sex.sexcheck
echo "\n\nWe find one sex discrepancy and rectifying it by keeping the genotype sex"
echo "Using --update-sex function"

#Based on check-sex function, changing the problematic sex

echo "HG02597 HG02597 1" > sex_update.txt

plink --bfile "$output_file/GENOTYPE_Removed" \
--update-sex sex_update.txt \
--make-bed \
--out $output_file/GENOTYPE_FINAL



echo "\nFinal GENOTYPE_FINAL file"
echo "Head of .fam file"
head $output_file/GENOTYPE_FINAL.fam
echo "\n\nHead of .bim file"
head $output_file/GENOTYPE_FINAL.bim


#Removing intermediate files
rm $output_file/Updated_Genotype_data* $output_file/GENOTYPE_DATA* $output_file/GENOTYPE_UPDATE* allele_update.txt bim_alleles.txt manifest_alleles.txt duplicate.txt samples* marker*

echo "\n\nSuccessfully processed GENOTYPE_DATA file and named it GENOTYPE_FINAL"








# PROCESSING OF VCF FILE



echo "\nFile Processing of VCF FILE Started"
echo "Converting VCF to Plink Binary file"


# Convert VCF to PLINK binary

plink --vcf "$input_file/data_2019_07_08.vcf.gz" \
--make-bed \
--out $output_file/data_plink



echo "Head of vcf converted plink binary file"
echo "\nHead of .fam file"

head $output_file/data_plink.fam

echo "\n\nHead of .bim file"
head $output_file/data_plink.bim


echo " Updating one mismatched row"
echo "\nChanging HG01889a to HG01889"

#Found this one mismatch so had to be changed
echo "HG01889a HG01889a HG01889 HG01889" > update_ID.txt

plink --bfile $output_file/data_plink \
--update-ids update_ID.txt \
--make-bed \
--out $output_file/vcf_ID_update



#Update Sex

awk 'BEGIN {FS=OFS} NR==FNR {a[$1]=$5; next} $1 in a {print $1, $2, a[$1]}' $output_file/GENOTYPE_FINAL.fam $output_file/vcf_ID_update.fam > new_sex.txt
echo "Updating the sex from GENOTYPE_FINAL.fam file"

plink --bfile $output_file/vcf_ID_update \
--update-sex new_sex.txt \
--make-bed \
--out $output_file/vcf_sex


echo "\n\nHead of newly updated sex file i.e vcf_sex.fam"
head $output_file/vcf_sex.fam



echo "\n\nChecking for variants with MCR = 100%"

# QC for missingness

plink --bfile $output_file/vcf_sex \
--missing \
--out $output_file/data_QC


awk '$5 == 1 {print $2}' $output_file/data_QC.lmiss > markers_to_remove.txt
awk '$6 == 1 {print $1}' $output_file/data_QC.imiss > samples_to_remove.txt



echo "\nRemoving the variants for MCR = 100%"
echo "\n Output of filtered data_QC.lmiss i.e markers_to_remove.txt"
head markers_to_remove.txt
echo "\n Output of filtered data_QC.lmiss i.e samples_to_remove.txt"
head samples_to_remove.txt



# Remove problematic markers and samples

plink --bfile $output_file/vcf_sex \
--remove samples_to_remove.txt \
--exclude markers_to_remove.txt \
--make-bed \
--out $output_file/vcf_final



echo "After final processing of vcf converted to plink file"

echo "\nHead of vcf_final.fam"
head $output_file/vcf_final.fam
echo "\n\nHead of vcf_final.bim"
head $output_file/vcf_final.bim



#Removing intermediate files
rm markers_to_remove.txt samples_to_remove.txt $output_file/vcf_sex* $output_file/data_plink* $output_file/data_QC* $output_file/vcf_ID_update*

echo "\n\nSuccessfully processed data_2019_07_08.vcf.gz file and named it vcf_final"




echo "\nFILE PROCESSING OF apoe_genotype.txt"


echo "Need to make the alleles in more human readable format"

#Step 1: Make the text file in human readable format

awk -F',' 'NR==1 {print $0",rs429358_T"; next} {print $0","(2-$2)}' "$input_file/apoe_genotype.txt" | tr ',' '\t'> apoe_genotype_with_T.txt
awk -F'\t' 'NR > 1{print $1"\t"($2 == 2 ? "C\tC" : ($2 == 1 ? "C\tT" : "T\tT"))}' apoe_genotype_with_T.txt > apoe_with_C_T.txt


echo "Head of .txt file with proper allele format"
head apoe_with_C_T.txt



#Step 2: Match IDs in the FAM file with those in the APOE file

awk 'BEGIN {FS=OFS} NR==FNR {a[$1]=$2" "$3; next} $1 in a {print $1, $2, $3, $4, $5, $6, a[$1]}' apoe_with_C_T.txt $output_file/GENOTYPE_FINAL.fam > $output_file/apoe_genotype.ped
echo "\n\nHead of .ped file"
head $output_file/apoe_genotype.ped


#Step 3: Create .map file 

echo -e "0\trs429358\t0\t0" > $output_file/apoe_genotype.map
echo "\n\nHead of .map file"
head $output_file/apoe_genotype.map



echo "Making binary files from .ped and .map file"



#Step 4: Making Binary files from ped and map file

plink --file "$output_file/apoe_genotype" \
--make-bed \
--out $output_file/apoe_bin



echo "\n\nBinary files generated"
echo "Head of .fam file"
head $output_file/apoe_bin.fam


echo "\n\nHead of .bim file"
head $output_file/apoe_bin.bim


echo "\n\nUsing the --missing function"



#Step 5: QC check for MCR=100%

plink --bfile "$output_file/apoe_bin" \
--missing \
--out $output_file/apo_QC


awk '$5 == 1 {print $2}' $output_file/apo_QC.lmiss > markers_to_remove.txt
awk '$6 == 1 {print $1}' $output_file/apo_QC.imiss > samples_to_remove.txt


#Step 6: Remove problematic markers and samples

plink --bfile "$output_file/apoe_bin" \
--remove samples_to_remove.txt \
--exclude markers_to_remove.txt \
--make-bed \
--out $output_file/Apoe_final



echo "\n\nFinished removing problematic markers and samples"
echo "Head of apoe.fam file"
head $output_file/Apoe_final.fam



echo "\n\nHead of .bim file"
head $output_file/Apoe_final.bim



echo "Not using the --check-sex function since the sex has been taken from Genotype file and that file has been checked for sex and rectified"
echo "Processing of Apoe file completed successfully"



#Removing the intermediate files.
rm $output_file/apo_QC* $output_file/apoe_bin* $output_file/apoe_genotype* apoe_genotype_with_T.txt apoe_with_C_T.txt

echo "Successully Completed Processing of apoe_genotype.txt and now named Apoe_final"



echo " Matching the Individual ID"
echo "Since the IDs of Apoe_Final has been taken from GENOTYPE_FINAL, it will be same"
echo "Checking for Individual ID between GENOTYOE_FINAL and vcf_final"
echo "To achieve this I have extracted the second column of GENOTYPE_FINAL and vcf_final and save it 2 different .txt file"
echo "Then we sort it and apply the diff command to see the different IID"



cut -d' ' -f2 $output_file/GENOTYPE_FINAL.fam > GENOTYPE_DATA_sample_ids.txt
cut -d' ' -f2 $output_file/vcf_final.fam > vcf_data_sample_ids.txt
sort GENOTYPE_DATA_sample_ids.txt -o GENOTYPE_DATA_sample_ids.txt
sort vcf_data_sample_ids.txt -o vcf_data_sample_ids.txt
diff GENOTYPE_DATA_sample_ids.txt vcf_data_sample_ids.txt > id_differences.txt



echo "The Individual IDs between the two files matches "
head id_differences.txt


echo "Merging the GENOTYPE_FINAL and vcf_final datasets"

# Merge the two datasets

plink --bfile $output_file/GENOTYPE_FINAL \
--bmerge $output_file/vcf_final \
--make-bed \
--out $output_file/merged_GENO_VCF



echo "Finished merging the two dataset"
echo "Merging the two merged datasets named merged_GENO_VCF with Apoe_Final dataset"



# Merge APOE genotypes

plink --bfile $output_file/merged_GENO_VCF \
--bmerge $output_file/Apoe_final \
--make-bed \
--out $output_file/final_dataset



echo "Finished merging all the dataset"
echo "Head of the merged dataset named final_dataset.fam"
head $output_file/final_dataset.fam



echo "\n\nfinal_dataset.bim"
head $output_file/final_dataset.bim



#Removing the intermediate file
rm $output_file/merged_GENO_VCF* *.txt


echo "Total number of variants : " | wc -l $output_file/final_dataset.bim
echo "Total number of samples : " | wc -l $output_file/final_dataset.fam


echo "\n\n\nSuccessfully completed PROJECT 2"
