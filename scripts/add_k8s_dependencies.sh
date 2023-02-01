#!/bin/bash -eu

echo "==> Adding repos for Kubernetes and necessary packages"

# software-properties-common is requrired for apt-add-repository
sudo apt-get install -y curl software-properties-common

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
