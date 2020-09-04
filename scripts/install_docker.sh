#!/bin/bash -eu

echo "==> Installing Docker"
apt-get -y update
apt-get -y install docker.io
systemctl enable docker
systemctl start docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

