#!/bin/bash -eu

# this script will add a static ip the 2nd nic
# I just learned that this is using netplan
# packer would not allow me to config a 2nd nic so 
# this is what I came up with.
echo "==> Configuring the 2nd NIC"

NICCOUNT=$(ls -A /sys/class/net | wc -l )

if [[ ${NICCOUNT} -eq 3 ]]; then
    NICNAME=$(ip a | grep "^3:" | awk '{print $2}' | cut -f1 -d: )
cat <<EOT >> /etc/netplan/01-netcfg.yaml
    ${NICNAME}:
        dhcp4: no
        addresses: [192.168.57.99/24]
        nameservers:
            addresses: [192.168.57.1]   
EOT
    netplan apply
    exit 0
fi

# something is wrong 
exit 1