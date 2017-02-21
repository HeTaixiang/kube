#!/bin/bash
set -e

source util.sh
source flannel-docker.sh
source docker.sh
source kubelet.sh

# List of etcd servers (http://ip:port), comma separated
export ETCD_ENDPOINTS=

# The endpoint the worker node should use to contact controller nodes (https://ip:port)
# In HA configurations this should be an external DNS record or loadbalancer in front of the control nodes.
# However, it is also possible to point directly to a single control node.
export CONTROLLER_ENDPOINT=

# Specify the version (vX.Y.Z) of Kubernetes assets to deploy
export K8S_VER=$(curl -sSL "https://storage.googleapis.com/kubernetes-release/release/stable.txt")

# Hyperkube image repository to use.
export HYPERKUBE_IMAGE_REPO=docker.zhimei360.com/hyperkube-amd64

# The IP address of the cluster DNS service.
# This must be the same DNS_SERVICE_IP used when configuring the controller nodes.
export DNS_SERVICE_IP=10.3.0.10

# Whether to use Calico for Kubernetes network policy.
export USE_CALICO=false

# Determines the container runtime for kubernetes to use. Accepts 'docker' or 'rkt'.
export CONTAINER_RUNTIME=docker

# Bootstrap docker connect endpoint
export DOCKER_BOOTSTRAP_SOCK=${DOCKER_BOOTSTRAP_SOCK:-"unix:///var/run/docker-bootstrap.sock"}

export POD_NETWORK=10.2.0.0/16

# The above settings can optionally be overridden using an environment file:
ENV_FILE=/run/kubelet/options.env

# -------------

function init_config {
    local REQUIRED=( 'ADVERTISE_IP' 'ETCD_ENDPOINTS' 'CONTROLLER_ENDPOINT' 'DNS_SERVICE_IP' 'K8S_VER' 'HYPERKUBE_IMAGE_REPO' 'USE_CALICO' 'DOCKER_BOOTSTRAP_SOCK' 'POD_NETWORK')

    if [ -f $ENV_FILE ]; then
        export $(cat $ENV_FILE | xargs)
    fi

    if [ -z $ADVERTISE_IP ]; then
        export ADVERTISE_IP=$(ip -o -4 addr list eth1 | awk '{print $4}'| cut -d/ -f1 | head -1)
    fi

    for REQ in "${REQUIRED[@]}"; do
        if [ -z "$(eval echo \$$REQ)" ]; then
            echo "Missing required config value: ${REQ}"
            exit 1
        fi
    done
}

function config_worker() {
  sed -i.back "s#\${HYPERKUBE_IMAGE_REPO}#${HYPERKUBE_IMAGE_REPO}#g" /etc/kubernetes/manifests/kube-proxy.yaml
  sed -i.back "s#\$K8S_VER#${K8S_VER}#g" /etc/kubernetes/manifests/kube-proxy.yaml
  sed -i.back "s#\${POD_NETWORK}#${POD_NETWORK}#g" /etc/kubernetes/manifests/kube-proxy.yaml
  sed -i.back "s#\${CONTROLLER_ENDPOINT}#${CONTROLLER_ENDPOINT}#g" /etc/kubernetes/manifests/kube-proxy.yaml
  sed -i.back "s#\${ADVERTISE_IP}#${ADVERTISE_IP}#g" /etc/kubernetes/manifests/kube-proxy.yaml
  rm -fr /etc/kubernetes/manifests/*.back
}


# init env
init_config

# install docker
# kube::docker::install
# start bootstrap-docker
kube::docker::init_bootstrap_docker
kube::docker::start_bootstrap_docker

# init flannel
kube::flannel::init
kube::flannel::start
kube::flannel::export_subnet_env

# init docker
kube::docker::init_docker
kube::docker::start_docker
# kube::docker::pull_image

# config kubernetes worker yaml
config_worker
# config kubelet service env
kube::kubelet::compatible
kube::kubelet::install
kube::kubelet::init
kube::kubelet::start
echo "DONE"
