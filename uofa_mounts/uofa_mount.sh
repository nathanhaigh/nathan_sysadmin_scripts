#!/bin/bash
# Usage: ./uofa_mount.sh a1640443
#        ./uofa_mount.sh a1640443 /home/nhaigh/some_mount_point
# Requires:
#   apt install -y cifs-utils
# Get UofA user ID from first command line argument
#####
CIFS_USERNAME="${1:-a1234567}"
MOUNT_POINT="${2:-${HOME}/uofa/home}"

# May want to change these
#####
CIFS_CREDENTIALS_FILE="${HOME}/.uofacredentials"

# Probably shouldn't change these
#####
CIFS_DOMAIN="${UOFA_DOMAIN:-UOFA}"
USER_ID=$(id --user ${USER})
GROUP_ID=$(id --group ${USER})

# Setup credentials file
#####
cat <<EOM > "${CIFS_CREDENTIALS_FILE}"
domain=${CIFS_DOMAIN}
username=${CIFS_USERNAME}
# Use your own UofA password:
password=nopassword
EOM
# Set correct owner and permissions on the credentials file
chmod 600 "${CIFS_CREDENTIALS_FILE}"
#chown "${USER_ID}:${GROUP_ID}" "${CIFS_CREDENTIALS_FILE}"

# Setup mount point in /etc/fstab
#####
mkdir -p "${MOUNT_POINT}"
cat <<EOM
#####
# Next steps:
#  1. Update the password line in ${CIFS_CREDENTIALS_FILE}
#  2. Mount the directory using:
sudo mount -t cifs -o defaults,vers=1.0,uid=${USER_ID},gid=${GROUP_ID},credentials=${CIFS_CREDENTIALS_FILE},iocharset=utf8,sec=ntlm //uofausers${CIFS_USERNAME: -1}.ad.adelaide.edu.au/users${CIFS_USERNAME: -1}/${CIFS_USERNAME} ${MOUNT_POINT}
#  3. To make the mount permanent and available following a reboot, add the following line to /etc/fstab (requires sudo):
//uofausers${CIFS_USERNAME: -1}.ad.adelaide.edu.au/users${CIFS_USERNAME: -1}/${CIFS_USERNAME} ${MOUNT_POINT} cifs defaults,vers=1.0,uid=${USER_ID},gid=${GROUP_ID},credentials=${CIFS_CREDENTIALS_FILE},iocharset=utf8,sec=ntlm 0 0
#####
EOM
