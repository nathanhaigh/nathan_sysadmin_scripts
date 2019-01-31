# Mount Phoenix Locally

The typical route to mounting phoenix on your local Linux machine is to use `sshfs` something like this:

```bash
# Install sshfs
sudo apt install -y \
  sshfs

# Set the remote phoenix username
PHOENIX_USERNAME='a1234567'

# Copy your SSH key to phoenix - you are using these right!? If not, create a keypair first by running:
# ssh-keygen
ssh-copy-id "${PHOENIX_USERNAME}@phoenix.adelaide.edu.au"

# Create the directory where you want to mount the root of phoenix
LOCAL_MOUNTPOINT="${HOME}/uofa/phoenix"
mkdir -p "${LOCAL_MOUNTPOINT}"

# Now mount it
sshfs "${PHOENIX_USERNAME}@phoenix.adelaide.edu.au:/" "${LOCAL_MOUNTPOINT}"
```

One issue you will start to notice is that the connection goes stale or gets disconnected after some time. You then have to
manually unmount and remount using:

```bash
# Unmount
fusermount -u "${LOCAL_MOUNTPOINT}"

# Remount
sshfs "${PHOENIX_USERNAME}@phoenix.adelaide.edu.au:/" "${LOCAL_MOUNTPOINT}"
```

Ugh, what a pain! There is another option:

## Automount with systemd

Recent versions of Ubuntu (> 14.04) use `systemd` to manage services. We can delegate the management of our phoenix mounts to `systemd` so
it takes care mounting/remounting,, so we don't have to!

All we have to do is add a line to `/etc/fstab` and refresh `systemd` so it can start to manage this mount point:

```bash
# Set the remote phoenix username
PHOENIX_USERNAME='a1234567'

# Grab some variables from the environment regarding the current user
LOCAL_USERNAME="${USER}"
LOCAL_UID=$(id -u)
LOCAL_GID=$(id -g)

# Generate the fstab entry and append to /etc/fstab file
echo "${PHOENIX_USERNAME}@phoenix.adelaide.edu.au:/  /home/${LOCAL_USERNAME}/uofa/phoenix  fuse.sshfs noauto,x-systemd.automount,_netdev,user,idmap=user,follow_symlinks,identityfile=/home/${LOCAL_USERNAME}/.ssh/id_rsa,allow_other,default_permissions,uid=${LOCAL_UID},gid=${LOCAL_GID} 0 0" \
  | sudo tee --append /etc/fstab

# Reload systemd to pick up configuration changes
sudo systemctl daemon-reload

# Identify the unit name of our phoenix automount
sudo systemctl list-unit-files --type automount

# Restart the automount using the name identified above - this might work just as it is:
sudo systemctl restart home-${LOCAL_USERNAME}-uofa-phoenix.automount
```

You now have a phoenix mount point with the following features:

 1. It automounts at boot
 2. It automounts after the connection drops unexpectedly
