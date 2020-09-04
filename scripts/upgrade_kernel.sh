#!/bin/bash -eu

echo "==> Upgrading to the latest kernel"
apt-get -y update
apt-get -y dist-upgrade
halt --reboot  
