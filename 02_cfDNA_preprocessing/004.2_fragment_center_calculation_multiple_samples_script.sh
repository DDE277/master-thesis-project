#!/bin/bash

# 1) Directory where all per-chromosome TSV files will be stored
BASE_OUTDIR="/mnt/DATA3/daniel/project/02_cfDNA_preprocessing/data/01_fragment_counts/cfDNA_cancer_samples"
mkdir -p "${BASE_OUTDIR}"

# 2) List all samples to process
SAMPLES=(
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

# 3) Process each sample
for SAMPLE in "${SAMPLES[@]}"; do

  # Define the BAM for this sample
  input_bam="/mnt/DATA2/cfDNA_finaledb/BAM/True25630XA/${SAMPLE}.sortByCoord.bam"

  # Check that the BAM file exists (optional safety check)
  if [[ ! -f "$input_bam" ]]; then
    echo "WARNING: BAM file not found for $SAMPLE: $input_bam"
    continue
  fi

  # Create a subdirectory for this sample
  OUTDIR="${BASE_OUTDIR}/${SAMPLE}"
  mkdir -p "${OUTDIR}"

  # Grab the list of relevant chromosomes from the BAM index
  chromosomes=$(samtools idxstats "$input_bam" \
               | cut -f1 \
               | grep -E '^chr([1-9]|1[0-9]|2[0-2]|X|Y)$')

  echo "Processing sample: $SAMPLE"

  # 4) Process all chromosomes in parallel (xargs -P 4 uses 4 threads)
  echo "$chromosomes" | xargs -n 1 -P 4 bash -c '
    chrom="$0"
    bam="'"$input_bam"'"
    outdir="'"$OUTDIR"'"

    # Get chromosome length from the BAM header
    chrom_len=$(samtools view -H "$bam" | grep "@SQ" | grep "SN:${chrom}" | awk -F "LN:" '"'"'{print $2}'"'"')

    # Generate counts for fragment centers on this chromosome
    samtools view -F 0x10 "$bam" "$chrom" | \
      awk -v chrom="$chrom" '"'"'
      BEGIN {OFS="\t"}
      {
        fragment_length = ($9 >= 0) ? $9 : -$9
        if (fragment_length >= 120 && fragment_length <= 200) {
          # Midpoint calculation
          midpoint = int(($4 + $4 + fragment_length - 1) / 2);
          print midpoint;
        }
      }
      '"'"' \
    | sort -n \
    | uniq -c \
    | awk '"'"'BEGIN {OFS="\t"} {print $2, $1}'"'"' \
    > "${outdir}/${chrom}_counts.tmp"

    # Fill in missing positions with zero
    awk -v chrom="$chrom" -v chrom_len="$chrom_len" '"'"'
    BEGIN {
      OFS="\t";
      pos = 1
    }
    {
      # Fill zeros up to the first observed position
      if (NR == 1) {
        while (pos < $1) {
          print chrom, pos, 0
          pos++
        }
      }
      # Fill zeros between the last position and current position
      while (pos < $1) {
        print chrom, pos, 0
        pos++
      }
      # Print the actual count
      print chrom, $1, $2
      pos = $1 + 1
    }
    END {
      # Fill zeros to the end of the chromosome
      while (pos <= chrom_len) {
        print chrom, pos, 0
        pos++
      }
    }
    '"'"' "${outdir}/${chrom}_counts.tmp" \
    | gzip > "${outdir}/${chrom}.tsv.gz"

    # Clean up
    rm -f "${outdir}/${chrom}_counts.tmp"

    echo "Processed chromosome: $chrom for sample: '"$SAMPLE"'"
  '
done

echo "All samples processed."
