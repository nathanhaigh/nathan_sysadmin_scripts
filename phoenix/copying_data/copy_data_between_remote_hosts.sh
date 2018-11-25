#!/usr/bin/env bash
usage() {
>&2 cat << EOM
  Usage:
    $(basename $0) -f <src> -t <dest> [ -h ]

  Rsync files/directories from one remote source to another remote source via a tunnel through your localhost.

  Options:
    -f from (e.g. user1@host1:/my/src/path)
    -t to (e.g. user2@host2:/my/dest/path)
    -h this help
EOM
    exit 1
}

# Define colours for STDERR text
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

while getopts ":f:t:h:" o; do
  case "${o}" in
    f)
      SRC="${OPTARG}"
      ;;
    t)
      DEST="${OPTARG}"
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

# Check required commandline arguments are specified
if [ -z "${SRC}" ]; then
  >&2 echo -e "${RED}ERROR: -f must be specified${NC}"
  usage
fi
if [ -z "${DEST}" ]; then
  >&2 echo -e "${RED}ERROR: -t must be specified${NC}"
  usage
fi

#SRC='nwhaigh@dawn:/var/www/DAWN/jbrowse-prod/data/local/wheat_full/references/161010_Chinese_Spring_v1.0_pseudomolecules.fasta.gz'
#DEST='a1640443@phoenix.adelaide.edu.au:/fast/users/a1640443/biorefs/wheat/IWGSC_RefSeq_v1.0/'

# Extract the various components from the provided SRC and DEST
SRC_FILE="${SRC#*:}"
DEST_FILE="${DEST#*:}"

SRC="${SRC%:*}"
DEST="${DEST%:*}"

SRC_USER="${SRC%@*}"
DEST_USER="${DEST%@*}"

SRC_HOST="${SRC#*@}"
DEST_HOST="${DEST#*@}"

ssh -A -R localhost:50000:${DEST_HOST}:22 ${SRC_USER}@${SRC_HOST} 'rsync -e "ssh -p 50000 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -av -P /var/www/DAWN/jbrowse-prod/data/local/wheat_full/references/161010_Chinese_Spring_v1.0_pseudomolecules.fasta.gz '${DEST_USER}'@localhost:/fast/users/a1640443/biorefs/wheat/IWGSC_RefSeq_v1.0/'
