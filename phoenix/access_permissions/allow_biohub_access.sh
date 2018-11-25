#!/usr/bin/env bash
usage() {
>&2 cat << EOM
  Usage:
    $(basename $0) -d <directory> [-u <user> | -g <group> ] [ -x ] [ -h ]

  Options:
    -d directory to which you want to provide access for the specified user/group 
    -u user to which you want to provide access
    -g group to which you want to provide access (e.g. phoenix-hpc-biohub)
    -h this help

  Options not yet implemented:
    -x revoke permissions for the specified user/group

EOM
    exit 1
}

# Define colours for STDERR text
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

while getopts ":d:u:g:xh:" o; do
  case "${o}" in
    d)
      project_dir="${OPTARG}"
      ;;
    u)
      u="${OPTARG}"
      ;;
    g)
      g="${OPTARG}"
      ;;
    x)
      >&2 echo -e "${RED}ERROR: Removing permissions (-x) is not yet supported${NC}"
      usage
      x='remove'
      # TODO - need to strip permissions from executed setfacl commands for this to work
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
if [ -z "${u}" ] && [ -z "${g}" ]; then
  >&2 echo -e "${RED}ERROR: Either -u or -g must be specified${NC}"
  usage
fi
if [ -z "${project_dir}" ]; then
  >&2 echo -e "${RED}ERROR: -d must be specified${NC}"
  usage
fi

# Validate the inputs
if [ ! -d "${project_dir}" ]; then
  >&2 echo -e "${RED}ERROR: Directory (${project_dir}) does not exist${NC}"
  usage
fi
if [ "${u}" ]; then
  if [ ! "$(id -u "${u}" 2> /dev/null)" ]; then
    >&2 echo -e "${RED}ERROR: User (${u}) does not exist${NC}"
    usage
  fi
  perm_prefix="u"
  perm_id="${u}"
fi
if [ "${g}" ]; then
  if [ ! "$(getent group "${g}")" ]; then
    >&2 echo -e "${RED}ERROR: Group (${g}) does not exist${NC}"
    usage
  fi
  perm_prefix="g"
  perm_id="${g}"
fi
if [ -z "${x}" ]; then
  # User has not asked for permissions to be removed, therefore we assume we're modifying
  x='modify'
fi

cat << EOM
###############################
Execute the following commands:
###############################
EOM
echo -ne "${ORANGE}"


# Lets ensure correct permissions are set on all files/directories in the subtree
#####
# For the specified directory, recursively:
#  1) Set default permission on newly created files/directories, be setting the defrault ACL, so the specified user will be able to see them
#  2) Set permissions on existing files/directories so the specified user will be able to see them
echo setfacl --recursive --default "--${x}" "${perm_prefix}:${perm_id}:rX" "${project_dir}"
echo setfacl --recursive "--${x}" "${perm_prefix}:${perm_id}:rX" "${project_dir}"

# Lets ensure the correct permissions are set on the parent directories, all the way up to a directory not owned by the current user
#####
# Traverse the directory structure from bottom upwards, enabling:
#  1) Set execute permission on directories for the specified user/group - this allows the user/group to cd into the directory and
#     nothing else, as long all parent directories also have execute permissions
#  2) Set read permission on the specified directory, enabling the specified user/group to list its contents
#  3) Recursively set existing files, under the specified directory, to readable by the specified user/group
#  4) Recursively set existing directories, under the specified directory, to readable and executable by the specified user/group
#  5) Ensure new files/directories will get permissions allowing the specified user/group access to them
branch="${project_dir}"
prev_dir="${project_dir}"
echo setfacl "--${x}" "${perm_prefix}:${perm_id}:rx" "${branch}"
echo setfacl --default "--${x}" "${perm_prefix}:${perm_id}:rx" "${branch}"
while branch="$(dirname "${branch}")"; do
  # Stop recursing into higher parent directories if the directory is not owned by the current user
  if [ "${USER}" != "$(stat -c %U "${branch}")" ]; then
    # Ensure the entire directory tree starting at the top-most directory owned by the user is not readable by the whole world. This is because
    # making a top-level directory executable by the specified user will enable them to read all existing files which have o=rx by default
    echo find "${prev_dir}" -xdev -perm /o=rwx -exec chmod o-rwx {} +
    break
  fi
  
  # Allow the specified user/group to be able to "cd" into this directory
  echo setfacl "--${x}" "${perm_prefix}:${perm_id}:x" "${branch}" || break
  
  if [ "${branch}" = / ]; then
    # Definately need to stop when we hit the root directory
    break
  fi

  # Keep track of the previous directory processed
  prev_dir="${branch}"
done

echo -e "${NC}###############################"

echo "To ensure newly created files and directories won't be readable by other,"
echo "ensure the following line is present in ~/.bash_profile"
echo "umask u=rwx,g=rx,o="

echo "###############################"
