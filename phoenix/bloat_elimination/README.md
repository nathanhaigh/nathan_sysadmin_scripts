# Finding Ways to Make Space

Lets set up some variables so we only operate on "old" files in a certain directory.

```bash
DIR='/home'
MODIFIED_MORE_THAN_DAYS=7
MIN_SIZE='1G'
```

## Identify Large Uncompressed Plain Text Files

Large plain text files can be easily compressed to same space. Here, we look for such files which
have not been modified recently.

```bash
# These chock on large text files with long lines
#time find "${DIR}" -xdev -type f -size +"${MIN_SIZE}" -mtime +$((MODIFIED_MORE_THAN_DAYS-1)) -not \( -name "*.bam" -o -name "*.gz" -o -name \) -exec grep -Iq . {} \; -print > /dev/null
#time find "${DIR}" -xdev -type f -size +"${MIN_SIZE}" -mtime +$((MODIFIED_MORE_THAN_DAYS-1)) -not \( -name "*.bam" -o -name "*.gz" -o -name \) -print0 | xargs -0 grep -Ilm1 .  > /dev/null

# This doesn't choke on large text files and should be safe with filenames containing spaces
time find "${DIR}" -xdev -depth -type f -size +"${MIN_SIZE}" -mtime +$((MODIFIED_MORE_THAN_DAYS-1)) -not \( -name "*.bam" -o -name "*.gz" -o -name "*.bz2" \) -print0 \
  | xargs -0 file -n0iN \
  | fgrep -wa 'text/plain;' \
  > /tmp/candidate_large_plain_text_files.list

# Report the sizes of the large, plain-text files
cut -f1 -d '' /tmp/candidate_large_plain_text_files.list \
  | tr '\n' '\0' \
  | xargs -0 du -ch \
  | sort -h \
  | tee /tmp/large_plain_text_files.list
```

## Idenitfy Superfluous Directories Left by Bioinformatics Tools

Many bioinformatics tools create temporary files which can end up being left laying around
consuming space. Let's try to identify these:

### STAR

```bash
find "${DIR}" -xdev -depth -type d -name ".STARtmp" -mtime +$((MODIFIED_MORE_THAN_DAYS-1)) -print0 \
  | xargs -0 du -chd0 \
  | sort -h \
  | tee /tmp/star_tmp_dirs.list
```

### MIRA

In most cases MIRA `.caf` and `.maf` files are not needed or could be compressed. Let's find them:

```bash
locate "*_d_results/*.maf" "*_d_results/*.caf" \
  | tr '\n' '\0' \
  | xargs -0 du -chd0 \
  | sort -h \
  | tee /tmp/mira_maf-caf.list
```

Let's also look for any MIRA `*_d_info` directories which may also not be needed:

```bash
locate _d_info \
  | tr '\n' '\0' \
  | xargs -0 du -chd0 \
  | sort -h \
  | tee /tmp/mira_info.list
```

## Identify Redundant Genome Indicies

TODO: 

* [ ] STAR
* [ ] Bowtie
* [ ] Bowtie2
* [ ] Biokanga
* [ ] BLAST+
* [ ] Minimap2

## Compress Large Plain-text files

### MIRA MAF/CAF Files

```bash
module load \
  pigz

TMP_OUT="$(mktemp /tmp/tmp.XXXXXXXXXX.gz)"

# Go through the MAF/CAF files and compress them
#  This is done by compressing to /tmp first
#  The owner and permissions of the compressed file are set to the same as the orignal uncompressed version
time cut -f2 /tmp/mira_maf-caf.list | grep '^/home' | grep -v '^total$' | while read F; do
  if [[ -e "${F}" ]]; then
    if [[ -s "${F}" ]]; then
      if [[ -e "${F}.gz" ]]; then
        echo "skipping (gz exists): $F"
      else
        echo "compressing: $F"
        pigz --best --stdout "${F}" > "${TMP_OUT}" \
          && chown --reference "${F}" "${TMP_OUT}" \
          && chmod --reference "${F}" "${TMP_OUT}" \
          && mv "${TMP_OUT}" "${F}.gz" && rm "${F}"
      fi
    else
      echo "skipping (zero size): $F"
    fi
  else
    echo "skipping (not exists): $F"
  fi
done

# Check owner of the compressed files
#cut -f2 /tmp/mira_maf-caf.list | grep '^/home' | grep -v '^total$' | while read F; do
#  stat -c '%U' "${F}.gz"
#done
```

# SAM Files

Identify `SAM` files for which we have a corresponding `BAM` file.

```bash
module load \
  SAMtools

# Set this ENV variable to anything in order to trigger an in-depth comparison of SAM/BAM files
#   which require a sorting of the data before a comparison can be made
#DEEP_CMP="1"

find /mnt/bioinf-? -xdev -type f -name "*.sam" \( -size +1G -and -size -1000G \) | while read SAM; do
  BAMS=()
  if [[ -e "${SAM}" ]]; then
    if [[ -s "${SAM}" ]]; then
      # Get a list of BAM files which might be equivilent to the SAM file
      if [[ -e "${SAM}.bam" ]]; then
        # .bam suffix added
        BAMS+=( "${SAM}.bam" )
      elif [[ -e "${SAM/.sam/.bam}" ]]; then
        # .bam replaced .sam suffix
        BAMS+=( "${SAM/.sam/.bam}" )
      elif [[ -e "${SAM/.sam/.sorted.bam}" ]]; then
        # .sorted.bam replaced .sam suffix
        BAMS+=( "${SAM/.sam/.sorted.bam}" )
      fi

      if [[ ${#BAMS[@]} -eq 0 ]]; then
        echo "${SAM} ... No BAM"
        continue
      fi

      # check each file in ${BAMS[@]}
      for BAM in ${BAMS[@]}; do
        # check BAM is equivilent of SAM
        #echo "Comparing ${BAM} to ${SAM}"
        read -r samfirstline<${SAM}
        bamfirstline=$( samtools view -h "${BAM}" | head -n 1 )

        if [[ "${samfirstline}" = "${bamfirstline}" ]]; then
          # SAM/BAM have the same first header line - Assume they are in the same sorting order
          echo -n "${SAM} <-> ${BAM} ... "
          
          cmp --silent \
            "${SAM}" \
            <(samtools view -h "${BAM}") \
            && echo "EQUAL" || echo "DIFF"
        else
          # SAM/BAM have different first headers - lets look what sorting we need to do
          #  in order to compare the files for equivilence
          samsortorder=${samfirstline#*SO:}
          bamsortorder=${bamfirstline#*SO:}

          if [[ "${samsortorder}" != "coordinate" && "${bamsortorder}" == "coordinate" ]]; then
            echo -n "${SAM} (${samsortorder}) <-> ${BAM} (${bamsortorder}) (SAM coordinate sorting) ... "
            
            if [[ ! -z "${DEEP_CMP}" ]]; then
              cmp --silent \
                <(samtools view -u "${SAM}" | samtools sort --threads 72 -T /tmp 2> /dev/null | samtools view -h) \
                <(samtools view -h "${BAM}") \
                && echo "EQUAL" || echo "DIFF"
            else
              echo "SKIPPING - DEEP_CMP not set"
            fi
          elif [[ "${samsortorder}" == "coordinate" && "${bamsortorder}" != "coordinate" ]]; then
            echo -n "${SAM} (${samsortorder}) <-> ${BAM} (${bamsortorder}) (BAM coordinate sorting) ... "

            if [[ ! -z "${DEEP_CMP}" ]]; then
              cmp --silent \
                "${SAM}" \
                <(samtools view -u "${BAM}" | samtools sort --threads 72 -T /tmp 2> /dev/null | samtools view -h) \
                && echo "EQUAL" || echo "DIFF"
            else
              echo "SKIPPING - DEEP_CMP not set"
            fi
          else
            echo "SAM/BAM - Dont know how to sort ${SAM} or ${BAM} - SKIPPING"
          fi
        fi
      done
    fi
  fi
done | tee --append ~/sam-bam_compare.txt
```

## Compress Directories

Compress the identified MIRA `*_d_info` directories if they are over 1G in size

```bash
module load \
  pigz

TMP_OUT="$(mktemp /tmp/tmp.XXXXXXXXXX.tar.gz)"

# Go through the MIRA *_d_info directories and compress them
#  This is done by compressing to /tmp first
#  The owner and permissions of the compressed file are transferred across from the original uncompressed directory
time cut -f2 ~/mira_info.list | grep -v '^total$' | while read D; do
  if [[ -e "${D}" ]]; then
    D_BYTE_SIZE=$(du -B 1 ${D} | cut -f1)
    if [[ "${D_BYTE_SIZE}" -gt 1073741824 ]]; then
      if [[ -e "${D}.tar.gz" ]]; then
        echo "skipping (.tar.gz exists): $D"
      else
        echo "compressing: $D"
        tar -cf - --directory "${D%/*}" "${D##*/}" \
          | pigz --best > "${TMP_OUT}" \
          && chown --reference "${D}" "${TMP_OUT}" \
          && chmod --reference "${D}" "${TMP_OUT}" \
          && chmod -x "${TMP_OUT}" \
          && mv "${TMP_OUT}" "${D}.tar.gz" && rm -rf "${D}"
      fi
    else
      echo "skipping (contents < 1G): $D"
    fi
  else
    echo "skipping (not exists): $D"
  fi
done
```
