#!/bin/bash

# Input BED file containing all chromosomes
input_bed="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/02_split_chromosomes/original_markers/trimmed_cell_type_markers_per_base.bed"

# Output directory for chromosome-specific BED files
output_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/02_split_chromosomes/original_markers/split_chromosomes/"

# Create output directory if it does not exist
mkdir -p "$output_dir"

echo "Starting to split $input_bed by chromosome..."

# Extract unique chromosome names from the BED file
chromosomes=$(cut -f1 "$input_bed" | sort | uniq)

# Set max parallel jobs
max_jobs=6
job_count=0

# Loop through each chromosome and create a separate BED file in parallel
for chrom in $chromosomes; do
    output_file="${output_dir}/${chrom}.bed"
    
    # Run awk in the background
    awk -v chr="$chrom" '$1 == chr' "$input_bed" > "$output_file" &
    
    echo "Created $output_file"

    # Manage background jobs
    ((job_count++))
    if (( job_count % max_jobs == 0 )); then
        wait  # Wait for all jobs to finish before launching new ones
    fi
done

# Wait for any remaining jobs
wait

echo "Finished splitting $input_bed by chromosome. Results are in $output_dir."
