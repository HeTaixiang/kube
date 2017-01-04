#!/bin/bash
set -e
source docker.sh
source etcd-docker.sh

# install docker
# kube::docker::install
kube::docker::start_docker

# init etcd
kube::etcd::export_etcd_env
kube::etcd::init
kube::etcd::start
