## ATAC pipeline overview

#### `001_adapter_detection_script.ipynb`
Detects adapter contamination in raw sequencing reads to inform trimming parameters.

#### `002_adapter_trimmomatic_script.ipynb`
Trims detected adapters using **Trimmomatic**, and performs basic quality filtering of raw FASTQ files.

#### `003_alignment_hg38_bowtie2_script.ipynb`
Aligns trimmed reads to the human reference genome (hg38) using **Bowtie2** for ATAC-seq data.

#### `004_post_alignment_processing_qc_checks_script.ipynb`
Performs post-alignment processing including:
- Removing mitochondrial reads
- Excluding reads in blacklisted regions
- Remove low-quality reads
- Computing QC metrics

#### `005_extraction_raw_count_regions_from_gabriel_script.ipynb`
Extracts raw read counts from genomic regions of interest

#### `006.1_count_reads_in_marker_regions_script.ipynb`
Counts reads specifically overlapping **cell-type marker regions**, preparing input for deconvolution.

#### `006.2_count_reads_in_reference_regions_hepa_script.ipynb`
Performs similar counting but focused on **hepatocyte-specific reference regions**.

#### `007_average_bigwig_replicates_corces_script.ipynb`
Averages multiple **bigWig signal tracks** (replicates from Corces ATAC-seq data) to reduce noise and enhance consistency.

#### `008_weighted_accessibility_scores_bigwig_corces_in_gabriel_reference_script.ipynb`
Calculates **weighted accessibility scores** by integrating averaged signal into the reference regions.

#### `009_merging_gabriel_corces_and_hepatocytes_samples_script.ipynb`
Merges preprocessed ATAC-Seq data from different sources (Gabriel, Corces, hepatocyte) to create the reference matrix for downstream analysis.
