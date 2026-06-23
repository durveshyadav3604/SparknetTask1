#!/bin/bash
set -euxo pipefail

# ---- Install Docker (Amazon Linux 2023) ----
dnf update -y
dnf install -y docker

# ---- Enable and start Docker service ----
systemctl enable docker
systemctl start docker

# ---- allow ec2-user to run docker without sudo ----
usermod -aG docker ec2-user