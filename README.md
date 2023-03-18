# proxmox-ubuntu-cloud-image-preperator
Configurable script that automates generation of ubuntu cloud image templates for Proxmox.

# Usage:

## Installation and Prerequisites

The Script is supposed to be run directly on a Proxmox Hypervisor, just download it i.E. into the root users directory.

### Dependencies

The script tries to install the follwing dependencies:

- wget (used for downloading the virtual machine image)
- libguestfs-tools (used for customizing the virtual machine image)


## Configuration

Configuration is done via exporting certain Environment variables.


```bash
export UBUNTU_RELEASE="22.04" # Available versions: 20.04, 21.10, 22.04, 22.10
export VM_NAME="ubuntu-${UBUNTU_RELEASE}-cloudimg"
export STORAGE_POOL="local-lvm"
export VM_ID="10000"
export USERNAME="ubuntu}"
export GITHUB_USERNAME="keyboardinterrupt" # This is used to grab the ssh public key for Login!
export PACKAGES_TO_INSTALL="qemu-guest-agent,htop" # coma seperated list of packages to install
```

## Run the script
```bash
bash proxmox-cloud-image-generator.sh
```

# TODO

- [ ] Improve README.md/documentation
- [ ] Remove temp directory created by the script


# Author

- [KeyboardInterrupt](https://keyboardinterrupt.com/)
