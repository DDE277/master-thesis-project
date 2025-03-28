#!/bin/bash

# List of sample IDs
samples=(
    EE87887
    EE87888
    EE87891
    EE87821
    EE88267
    EE87889
    EE87865
    EE88209
    EE88258
    EE88219
    EE88214
    EE87876
    EE88212
    EE87881
    EE88197
    EE88184
    EE88217
    EE88279
    EE88220
    EE88201
    EE88218
    EE88185
    EE88223
    EE88186
    EE88213
    EE88307
    EE87882
    EE87787
    EE88247
    EE88216
    EE88221
    EE88265
    EE88256
    EE88183
    EE88215
    EE87913
    EE88222
    EE88306
    EE88189
    EE88262
    EE88193
    EE87902
    EE88294
    EE87914
    EE87835
    EE88269
    EE88288
    EE87816
    EE87906
    EE87907
    EE87836
    EE87910
    EE88203
    EE88187
    EE88266
    EE88192
    EE88295
    EE87855
    EE87867
    EE88204
    EE88282
    EE87861
)

# Directory containing the split marker BED files for each chromosome
marker_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/02_split_chromosomes/new_markers/split_chromosomes"

# Number of parallel jobs for each sample’s chromosome processing
max_jobs=6

# Loop over each sample ID
for sample_id in "${samples[@]}"; do

    # Define input and output directories for this sample
    input_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/01_fragment_counts/cfDNA_cancer_samples/$sample_id"
    output_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/02_cfDNA_preprocessing/data/cfDNA_cancer_samples_new/$sample_id/mapped_counts"

    # Create output directory if it does not exist
    mkdir -p "$output_dir"

    echo "Starting intersection for sample $sample_id (up to $max_jobs chromosome jobs in parallel)..."

    # Loop through chromosome TSV files in the input directory
    for input_file in "$input_dir"/chr*.tsv.gz; do
        
        # If no files match, skip
        if [[ ! -e "$input_file" ]]; then
            continue
        fi

        # Extract the chromosome name (e.g., "chr1" from "chr1.tsv.gz")
        chrom=$(basename "$input_file" .tsv.gz)

        # Define corresponding marker BED file for this chromosome
        marker_bed="$marker_dir/${chrom}.bed"

        # Define final output file
        output_file="${output_dir}/${chrom}_markers_with_counts.bed"

        # Check if marker BED file exists for this chromosome
        if [[ -f "$marker_bed" ]]; then
            echo "  Processing $sample_id $chrom in background..."

            (
                # ---------------------------------------------------
                # Step A: Tag each line in the marker BED with row index
                # Step B: Sort by (chrom, start)
                # Step C: bedtools map
                # Step D: Re-sort by original line index
                # Step E: Remove the line index column
                # ---------------------------------------------------
                awk 'BEGIN {FS=OFS="\t"} {print $0, NR}' "$marker_bed" | \
                sort -k1,1V -k2,2n | \
                bedtools map \
                    -a - \
                    -b <(zcat "$input_file" | awk -v OFS="\t" '{print $1, $2-1, $2, $3}') \
                    -c 4 -o sum | \
                sort -k4,4n | \
                cut -f1-3,5 > "$output_file"

                echo "  Finished $sample_id $chrom → $output_file"
            ) &

            # Throttle to a maximum of $max_jobs background jobs
            while (( $(jobs -r | wc -l) >= max_jobs )); do
                sleep 1
            done
        else
            echo "  Skipping $sample_id $chrom: No corresponding marker BED file found at $marker_bed"
        fi
    done

    # Wait for all background chromosome jobs to complete for this sample
    wait

    # ---------------------------------------------------
    # Create a single all_counts.bed by concatenating
    # and sorting all chr*.bed for this sample
    # ---------------------------------------------------
    all_counts_file="${output_dir}/${sample_id}_all_counts.bed"
    echo "Concatenating results for $sample_id..."
    cat "${output_dir}"/chr*_markers_with_counts.bed | \
        sort -k1,1V -k2,2n > "$all_counts_file"
    echo "Created $all_counts_file."

    echo "Done with $sample_id. Results are in $output_dir."
    echo "----------------------------------------------"
done

echo "All samples processed."
