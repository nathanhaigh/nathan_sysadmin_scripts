#!/bin/bash
#####
# Usage info
#####
usage="USAGE: $(basename $0) [-h] -a <accession>... [-l <max bandwidth>] [-o <output dir>] [-f <field>]
Download FASTQ files associated with an SRA accession using Aspera.

  where:
    -h Show this help text
    -a SRA accession (SRR or ERR prefix)
       See https://www.ncbi.nlm.nih.gov/books/NBK56913/#search.what_do_the_different_sra_accessi
    -l Maximum bandwidth usage (default: 50m)
    -o Output directory (default: ./)
    -f Field containing fasp link info. (default: 'fastq_aspera').
       Could also be 'submitted_aspera'.

Parallelising with GNU parallel:
  N_PARALLEL=4
  LINK_AGGREGATE_BANDWIDTH_MBPS=1000
  cat my_accessions.txt | SHELL=\$(type -p bash) parallel --will-cite --jobs \"\${N_PARALLEL}\" --ungroup $(basename $0) -l \$((LINK_AGGREGATE_BANDWIDTH_MBPS/N_PARALLEL))m -a {} -o ./parent_dir/{}/"

#####
# Set default command line options
#####
max_bandwidth_mbps='50m'
accessions=()
out_dir='./'
fields=( 'run_accession' )

#####
# Parse command line options
#####
while getopts ":ha:l:o:f:" opt; do
  case $opt in
    h) >&2 echo "${usage}"
       exit
       ;;
    a) accessions+=(${OPTARG})
       ;;
    l) max_bandwidth_mbps=${OPTARG}
       ;;
    o) out_dir=${OPTARG}
       ;;
    f) fields+=(${OPTARG})
       ;;
    ?) >&2 printf "Illegal option: '-%s'\n" "${OPTARG}"
       >&2 echo "{$usage}"
       exit 1
       ;;
    :)
      >&2 echo "Option -${OPTARG} requires an argument."
      >&2 echo "${usage}"
      exit 1
      ;;
  esac
done

#####
# Validate/preprocess the inputs
#####
if [[ ${#accessions[@]} == 0 ]]; then
  >&2 echo "$usage"
  exit
fi

if [[ "${accession[@]}" != SRR* ]]; then
  >&2 echo "$usage"
  exit
fi

if [[ ${#fields[@]} == 1 ]]; then
  fields+=('fastq_aspera')
fi
fields=$(IFS=, eval 'echo "${fields[*]}"')

# Strip any trailing slash on the specified output directory, we'll add later when required
out_dir=${out_dir%/}

#####
# Now onto the program proper
#####
mkdir -p "${out_dir}"
for accession in ${accessions[@]}; do
  # TODO Consider creating a URL for ddbj instead of EBI: http://trace.ddbj.nig.ac.jp/dra/faq_e.html ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/fastq/SRA026/SRA026538/SRX186040/
  #   e.g. anonftp@ascp.ddbj.nig.ac.jp:/ddbj_database/dra/fastq/${submission_accession:0:6}/${submission_accession}/${accession}/${files}.fastq.bz2

  # Obtain run accessions for the requested submission accession
  url="http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=${accession}&result=read_run&fields=${fields}&download=text"
  wget --continue --no-clobber -O "${out_dir}/${accession}.metadata" "${url}"

  # Extract the requested field and reformat the URLs ready for use by aspera
  files=$(sed '1d' ${out_dir}/${accession}.metadata | cut -f 2 | tr ';' ' ' | sed 's/fasp.sra.ebi.ac.uk/era-fasp@fasp.sra.ebi.ac.uk/g')

  ascp \
    -i $(dirname $(which ascp))/../etc/asperaweb_id_dsa.openssh \
    -P 33001 \
    -k1 \
    -QTr \
    -l${max_bandwidth_mbps} \
    ${files} ${out_dir}/
done

