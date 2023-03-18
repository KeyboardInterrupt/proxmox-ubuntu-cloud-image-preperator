#!/bin/bash

# Configuration, can be overwritten by Environment variables
export UBUNTU_RELEASE="${UBUNTU_RELEASE:-22.04}" # Available versions: 20.04, 21.10, 22.04, 22.10
export VM_NAME="${VM_NAME:-ubuntu-${UBUNTU_RELEASE}-cloudimg}"
export STORAGE_POOL="${STORAGE_POOL:-local-lvm}"
export VM_ID="${VM_ID:-10000}"
export USERNAME="${USERNAME:-ubuntu}"
export GITHUB_USERNAME="${GITHUB_USERNAME:-keyboardinterrupt}" # Used to grab the ssh public Key for Login!
export PACKAGES_TO_INSTALL="${PACKAGES_TO_INSTALL:-qemu-guest-agent,htop}"

declare -a ubuntu_release_name=(
  ["20.04"]="focal"
  ["21.10"]="impish"
  ["22.04"]="jammy"
  ["22.10"]="kinetic"
)

# Install libguestfs-tools (dependency) on Proxmox server.
echo "Installing image customization tools, it can take some time..."
apt-get install -y libguestfs-tools wget

# System variables, DO NOT CHANGE them
export CLOUD_IMAGE_NAME="${ubuntu_release_name[$UBUNTU_RELEASE]}-server-cloudimg-amd64.img"
export CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/${ubuntu_release_name[$UBUNTU_RELEASE]}/current/$CLOUD_IMAGE_NAME"

# Switch into temporary directory
cd "$(mktemp -d)" || exit

# Download Ubuntu Image
wget "$CLOUD_IMAGE_URL"

# Add packages (qemu-guest-agent) to Ubuntu image.
virt-customize -a "$CLOUD_IMAGE_NAME" --install "$PACKAGES_TO_INSTALL"

# Create the initial User and inject the SSH Public Key(s) of the specified github user!
virt-customize -a "$CLOUD_IMAGE_NAME" --run-command "useradd -m ${USERNAME}"
virt-customize -a "$CLOUD_IMAGE_NAME" --run-command "mkdir /home/${USERNAME}/.ssh && curl https://github.com/${GITHUB_USERNAME}.keys | tee -a /home/${USERNAME}/.ssh/authorized_keys && chown -R .${USERNAME} /home/${USERNAME}/ "

# Create Proxmox VM image from Ubuntu Cloud Image.
qm create "$VM_ID" --cpu cputype=host --cores 4 --memory 4096 --net0 virtio,bridge=vmbr0
qm importdisk "$VM_ID" "$CLOUD_IMAGE_NAME" "$STORAGE_POOL"
qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE_POOL":vm-"$VM_ID"-disk-0
qm set "$VM_ID" --agent enabled=1,fstrim_cloned_disks=1
qm set "$VM_ID" --name "$VM_NAME"
qm set "$VM_ID" --ciuser "$USERNAME"

# Create Cloud-Init Disk and configure boot.
qm set "$VM_ID" --ide2 "$STORAGE_POOL":cloudinit
qm set "$VM_ID" --boot c --bootdisk scsi0
qm set "$VM_ID" --serial0 socket --vga serial0

# Convert VM into Template
qm template "$VM_ID"
