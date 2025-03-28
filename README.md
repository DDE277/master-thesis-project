# Master Thesis: Deconvoluting liquid biopsy cell-type compositions from nucleosome footprints

This repository contains piplines and scripts developed during my master's thesis at the University of Zurich. The project focuses on preprocessing ATAC-seq and cfDNA data, generating synthetic samples, analyzing cfDNA nucleosome footprints, and performing cell-type deconvolution using the EPIC-ATAC framework.

## Repository structure

- `01_ATAC_preprocessing/`  
  Pipeline to preprocess ATAC-Seq data including adapter trimming, quality control, alignment, and read counting

- `02_cfDNA_preprocessing/`  
  Pipeline to preprocess cfDNA-Seq data including cfDNA fragmenter center counts calculation, Whittaker and Gaussian smoothing, z-score normalization, and trimming. 

- `03_synthetic_samples/`  
  Scripts to generate synthetic samples with known cell-type proportions including down-sampling .

- `04_DA_and_reference_building/`  
  Scripts for pairwise differential accessibility analysis and new reference building for EPIC-ATAC.

- `05_EPIC_deconvolution/`  
  Scripts applying the EPIC-ATAC algorithm for cell-type deconvolution on cfDNA-Seq data.

## Packages and system-level tools

The required Python and R packages, as well as command-line tools, are listed in `requirements.txt`. Please ensure they are installed before running the scripts.


