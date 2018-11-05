# Prerequisites

The following packages are required on the host running the playbook:

  * ansible

Install them using:

```bash
sudo apt install ansible
```

The following packages are required on any host being configured by the playbook:

  * python-apt

Install them using:

```bash
sudo apt install python-apt
```

# Configure Hosts

Run the whole playbook on all hosts configured in the `hosts` file, but don't make any changes:

```bash
ansible-playbook --check -i hosts site.yml
```

Run the playbook for real and request we become become root on each target system in order to perform the tasks:

```bash
ansible-playbook --become --ask-become-pass -i hosts site.yml
```
