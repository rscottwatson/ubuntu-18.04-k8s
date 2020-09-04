#!/bin/bash -eu

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    apt-get install -y  linux-headers-$(uname -r) build-essential
    apt-get -y install --no-install-recommends dkms

    VBOX_VERSION=$(cat /home/${SSH_USER}/.vbox_version)
    mount -o loop /home/${SSH_USER}/VBoxGuestAdditions.iso /mnt
    yes|sh /mnt/VBoxLinuxAdditions.run
    umount /mnt
    rm /home/${SSH_USER}/VBoxGuestAdditions.iso

fi