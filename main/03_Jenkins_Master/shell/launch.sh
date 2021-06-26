#!/bin/bash
set -eux

yum -y update

# install ansible
yum -y install epel-release
yum -y update
yum -y install ansible

# install docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
usermod -a -G docker centos
systemctl enable docker
systemctl start docker
