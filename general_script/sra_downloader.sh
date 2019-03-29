#!/bin/bash
#####
# Usage info
#####
usage="USAGE: $(basename $0) [-h] -a <accession>... [-l <max bandwidth>] [-o <output dir>] [-f <field>] [-j <n parallel jobs>]
Download FASTQ files associated with an SRA accession using Aspera.

  where:
    -h Show this help text
    -a SRA accession (SRR or ERR prefix)
       See https://www.ncbi.nlm.nih.gov/books/NBK56913/#search.what_do_the_different_sra_accessi
    -l Maximum bandwidth usage (default: 50m)
    -o Output directory (default: ./)
    -f Field containing fasp link info. (default: 'fastq_aspera')
       Could also be 'submitted_aspera'.
    -j Number of parallel download jobs (default: 1)

The script requires the following executables on the path:
  ascp
  parallel"

#####
# Set default command line options
#####
max_bandwidth_mbps='50m'
accessions=()
out_dir='./'
fields=( 'run_accession' )
ascp_args=( '-P 33001' '-k1' '-QTr' )
parallel_jobs=1
parallel_args=( '--will-cite' '--ungroup' '--verbose' '--progress' )

#####
# Parse command line options
#####
while getopts ":ha:l:o:f:j:" opt; do
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
    j) parallel_jobs=${OPTARG}
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
  >&2 echo "ERROR: Must provide SRA accession."
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
  >&2 echo "Processing SRA accession: ${accession}"
  # TODO Consider creating a URL for ddbj instead of EBI: http://trace.ddbj.nig.ac.jp/dra/faq_e.html ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/fastq/SRA026/SRA026538/SRX186040/
  #   e.g. anonftp@ascp.ddbj.nig.ac.jp:/ddbj_database/dra/fastq/${submission_accession:0:6}/${submission_accession}/${accession}/${files}.fastq.bz2

  # Obtain run accessions for the requested submission accession
  >&2 echo -n "  Downloading run accession information: "
  url="http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=${accession}&result=read_run&fields=${fields}&download=text"
  wget --continue --no-clobber -O "${out_dir}/${accession}.metadata" "${url}"

  # Extract the requested field and reformat the URLs ready for use by aspera
  files=( $(sed '1d' ${out_dir}/${accession}.metadata | cut -f 2 | tr ';' '\n' | sed 's/fasp.sra.ebi.ac.uk/era-fasp@fasp.sra.ebi.ac.uk/g') )
  #>&2 echo "${files[@]}"
  >&2 echo "  Number of run accessions available: ${#files[@]}"

  PRIVATE_KEY_FILE=$(dirname $(which ascp))/../etc/asperaweb_id_dsa.openssh

  >&2 echo "  Number of parallel download jobs: ${parallel_jobs}"
  >&2 echo "  Executing parallel download via Aspera's ascp:"
  printf '%s\n' "${files[@]}" | SHELL=$(type -p bash) parallel --jobs "${parallel_jobs}" "${parallel_args[@]}" \
    ascp \
      -i "${PRIVATE_KEY_FILE}" \
      -l${max_bandwidth_mbps} \
      "${ascp_args[@]}" \
      "{}" ${out_dir}/
done

