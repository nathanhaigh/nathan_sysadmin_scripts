# Mount UofA Home Directory in Linux

```bash
# Mounting UofA shares requires CIFS
sudo apt install -y \
  cifs-utils

# Create mount point for UofA home and follow the instructions onscreen
./uofa_mount.sh a1640443
```
