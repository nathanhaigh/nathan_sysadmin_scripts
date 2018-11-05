# Mount UofA Home Directory in Linux

```bash
# Mounting UofA shares requires CIFS
sudo apt install -y \
  cifs-utils

# Create mount point for UofA home and follow the instructions onscreen
./uofa_mount.sh a1640443
```

# Considerations

***A credentials file will contain your password in cleartext.*** Unfortunately, it is not possible to store and use an encrypted
password in a credentials file. While the `uofa_mount.sh` script sets permissions on the credentials file so that only
the owner can read it's contents, anyone with `sudo` could use their elevated privileges to see the password. ***If this worries
you, do not use this script.***
