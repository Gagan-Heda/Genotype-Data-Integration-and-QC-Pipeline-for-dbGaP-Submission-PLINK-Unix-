# Genotype Data Integration and QC Pipeline for dbGaP Submission (PLINK + Unix)

A fully reproducible Unix and PLINK pipeline for integrating, harmonizing, and quality-controlling multi-platform genotype data into a dbGaP-ready dataset.

---

## Project Overview

This workflow integrates genotype data from multiple sources to produce a clean, merged dataset of 2,499 individuals suitable for dbGaP submission:

- SNP array data (PLINK binary format)  
- VCF-based genotype data  
- TaqMan assay genotype data (APOE variant)  

All steps are automated using Unix and PLINK to ensure reproducibility and compliance with dbGaP standards.

---

## Key Objectives

- Convert VCF genotype data into PLINK format  
- Harmonize allele encoding across datasets (ACGT standard)  
- Remove duplicate samples and resolve inconsistencies  
- Correct phenotype/genotype sex discrepancies  
- Standardize sample IDs across datasets  
- Construct missing genotype datasets (APOE variant)  
- Merge multiple genotype datasets  
- Perform quality control (QC) checks  
- Remove variants with high missingness  

---

## Pipeline Overview

### Step 1: VCF Conversion
- Convert VCF file to PLINK binary format using:
  - `--vcf`  
  - `--make-bed`  

### Step 2: Data Inspection and Validation
- Verified allele encoding (ACGT format)  
- Checked sample counts across datasets  
- Identified duplicate samples  
- Evaluated missing phenotype fields (e.g., sex)  

### Step 3: Data Cleaning
- Removed duplicate samples (`dup`)  
- Updated incorrect sex annotations using `--update-sex`  
- Harmonized allele coding with `--update-alleles` and a manifest file  

### Step 4: APOE Variant Processing
- Converted coded genotypes (0/1/2) into allele pairs:
  - 0 → T T  
  - 1 → C T  
  - 2 → C C  

- Generated `.ped` and `.map` files and converted to PLINK binary format  

### Step 5: Sample ID Harmonization
- Identified mismatched sample IDs  
- Corrected IDs using `--update-ids`  
- Ensured consistency across all datasets  

### Step 6: Data Merging
- Merged datasets in stages:
  - GENOTYPE + VCF  
  - Result + APOE  

- Verified sample counts and variant counts  

### Step 7: Quality Control (QC)
- Sex check: `--check-sex 0.9 0.99`  
- Missingness analysis: `--missing`  

### Step 8: Filtering
- Removed SNPs with 100% missing calls  
- Generated final filtered dataset  

---

## Technologies Used

- Unix (bash scripting)  
- PLINK v1.9  
- awk, grep, sort, join, diff  

---

## Input Data

- PLINK binary genotype files (.bed, .bim, .fam)  
- VCF genotype data (.vcf.gz)  
- TaqMan genotype data (text format)  
- SNP annotation file (`manifest.csv`)  

---

## Output

- Merged PLINK binary files (.bed, .bim, .fam)  
- Quality-controlled and filtered genotype dataset  

---

## Key Features

- Fully reproducible bash pipeline  
- Multi-platform genotype data integration  
- dbGaP submission compliance  
- SLURM-compatible execution for HPC environments  
- Efficient handling of large genomic datasets  

---

## Reproducibility

- Fully script-based workflow (no manual edits)  
- Error handling (`set -e`) and command tracing (`set -v`) included  
- Designed for high-performance computing (HPC) execution  

---

## Key Skills Demonstrated

- Genomic data processing with PLINK  
- Multi-source genotype integration  
- QC of genotype datasets  
- Unix scripting and workflow automation  
- HPC workflow execution  
- Data harmonization and validation  

---

## Notes

- Duplicate samples were removed  
- Sex discrepancies resolved using genotype data  
- SNPs with complete missingness excluded  

---

## Author

**Gagan Heda**
