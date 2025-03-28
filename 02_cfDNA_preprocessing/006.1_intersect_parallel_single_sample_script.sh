#!/bin/bash

# Define directories and marker BED directory
input_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/01_fragment_counts/cfDNA_healthy_samples/EE87933"
marker_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/02_split_chromosomes/new_markers/split_chromosomes"
output_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/03_intersect_mapped/cfDNA_healthy_new/EE87933/mapped_counts"

# Create output directory if it does not exist
mkdir -p "$output_dir"

# Number of parallel jobs
max_jobs=6

echo "Starting intersection for each chromosome (up to $max_jobs in parallel)..."

# Loop through chromosome TSV files in the input directory
for input_file in "$input_dir"/chr*.tsv.gz; do

    # Extract the chromosome name (e.g., chr1)
    chrom=$(basename "$input_file" .tsv.gz)

    # Define corresponding marker BED file
    marker_bed="$marker_dir/${chrom}.bed"

    # Define final output file
    output_file="${output_dir}/${chrom}_markers_with_counts.bed"

    # Check if marker BED file exists for this chromosome
    if [[ -f "$marker_bed" ]]; then
        echo "Processing $chrom in background..."

        (
            #---------------------------------------------------
            # Step A: Tag each line in the marker BED with row index
            #---------------------------------------------------
            awk 'BEGIN {FS=OFS="\t"} {print $0, NR}' "$marker_bed" | \
            
            #---------------------------------------------------
            # Step B: Sort by (chrom, start) in-memory
            #---------------------------------------------------
            sort -k1,1V -k2,2n | \
            
            #---------------------------------------------------
            # Step C: Use bedtools map
            #---------------------------------------------------
            bedtools map \
                -a - \
                -b <(zcat "$input_file" | awk -v OFS="\t" '{print $1, $2-1, $2, $3}') \
                -c 4 -o sum | \
            
            #---------------------------------------------------
            # Step D: Re-sort by original line index (column 4)
            #---------------------------------------------------
            sort -k4,4n | \

            #---------------------------------------------------
            # Step E: Remove the line index column (4) and keep coverage as the new 4th col
            #---------------------------------------------------
            cut -f1-3,5 > "$output_file"

            echo "Finished processing $chrom. Output: $output_file"
        ) &

        # Throttle parallel jobs
        while (( $(jobs -r | wc -l) >= max_jobs )); do
            sleep 1
        done
    else
        echo "Skipping $chrom: No corresponding marker BED file found."
    fi
done

# Wait for all background jobs to complete
wait

echo "All intersections completed. Results are stored in $output_dir."
