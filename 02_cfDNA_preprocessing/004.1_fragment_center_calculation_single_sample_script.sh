#!/bin/bash

# Define input BAM file
input_bam="/mnt/DATA2/cfDNA_finaledb/BAM/True25630XA/EE87933.sortByCoord.bam"

# Define output directory
output_dir="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/03_intersect_mapped/cfDNA_healthy/EE87933"

# Create output directory if it does not exist
mkdir -p "$output_dir"

# Function to process each chromosome
process_chromosome() {
    chrom=$1

    # Get chromosome length from BAM header
    chrom_len=$(samtools view -H "$input_bam" | grep "@SQ" | grep "SN:${chrom}" | awk -F 'LN:' '{print $2}')

    # Generate counts for fragment centers, filter by length
    samtools view -F 0x10 "$input_bam" "$chrom" | \
        awk -v chrom="$chrom" '
        BEGIN {OFS="\t"}
        {
            # Calculate fragment length from $9 (template length)
            fragment_length = ($9 >= 0) ? $9 : -$9;
            if (fragment_length >= 120 && fragment_length <= 200) {
                # Midpoint calculation
                midpoint = int(($4 + $4 + fragment_length - 1) / 2);
                print midpoint;
            }
        }' | \
        sort -n | \
        uniq -c | \
        awk 'BEGIN {OFS="\t"} {print $2, $1}' > "${output_dir}/${chrom}_counts.tmp"

    # Fill in missing positions with zeros
    awk -v chrom="$chrom" -v chrom_len="$chrom_len" '
    BEGIN {
        OFS="\t";
        pos = 1
    }
    {
        # If this is the first line, fill zeros up to the first observed position
        if (NR == 1) {
            while (pos < $1) {
                print chrom, pos, 0
                pos++
            }
        }
        # For subsequent lines, fill zeros between the last position and current position
        while (pos < $1) {
            print chrom, pos, 0
            pos++
        }
        # Print the actual count
        print chrom, $1, $2
        pos = $1 + 1
    }
    END {
        # Fill zeros from last observed position to chrom_len
        while (pos <= chrom_len) {
            print chrom, pos, 0
            pos++
        }
    }' "${output_dir}/${chrom}_counts.tmp" \
    | gzip > "${output_dir}/${chrom}.tsv.gz"

    # Remove the temporary file
    rm "${output_dir}/${chrom}_counts.tmp"

    echo "Processed chromosome: $chrom"
}

export -f process_chromosome
export input_bam
export output_dir

# Get a list of chromosomes from the BAM index
chromosomes=$(samtools idxstats "$input_bam" | cut -f1 | grep -E '^chr([1-9]|1[0-9]|2[0-2]|X|Y)$')

# Run the function in parallel
echo "$chromosomes" | xargs -n 1 -P 4 bash -c 'process_chromosome "$1"' _

