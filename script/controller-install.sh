#!/bin/bash
set -e

source util.sh
source docker.sh
source flannel-docker.sh
source kubelet.sh

# List of etcd servers (http://ip:port), comma separated
export ETCD_ENDPOINTS=

# Specify the version (vX.Y.Z) of Kubernetes assets to deploy
export K8S_VER=$(curl -sSL "https://storage.googleapis.com/kubernetes-release/release/stable.txt")

# Hyperkube image repository to use.
export HYPERKUBE_IMAGE_REPO=docker.zhimei360.com/hyperkube-amd64

# The CIDR network to use for pod IPs.
# Each pod launched in the cluster will be assigned an IP out of this range.
# Each node will be configured such that these IPs will be routable using the flannel overlay network.
export POD_NETWORK=10.2.0.0/16

# The CIDR network to use for service cluster IPs.
# Each service will be assigned a cluster IP out of this range.
# This must not overlap with any IP ranges assigned to the POD_NETWORK, or other existing network infrastructure.
# Routing to these IPs is handled by a proxy service local to each node, and are not required to be routable between nodes.
export SERVICE_IP_RANGE=10.3.0.0/24

# The IP address of the Kubernetes API Service
# If the SERVICE_IP_RANGE is changed above, this must be set to the first IP in that range.
export K8S_SERVICE_IP=10.3.0.1

# The IP address of the cluster DNS service.
# This IP must be in the range of the SERVICE_IP_RANGE and cannot be the first IP in the range.
# This same IP must be configured on all worker nodes to enable DNS service discovery.
export DNS_SERVICE_IP=10.3.0.10

# Whether to use Calico for Kubernetes network policy.
export USE_CALICO=false

# Determines the container runtime for kubernetes to use. Accepts 'docker' or 'rkt'.
export CONTAINER_RUNTIME=docker

export DOCKER_BOOTSTRAP_SOCK=${DOCKER_BOOTSTRAP_SOCK:-"unix:///var/run/docker-bootstrap.sock"}

# The above settings can optionally be overridden using an environment file:
ENV_FILE=/run/kubelet/options.env

# -------------
function init_config {
    local REQUIRED=('ADVERTISE_IP' 'POD_NETWORK' 'ETCD_ENDPOINTS' 'SERVICE_IP_RANGE' 'K8S_SERVICE_IP' 'DNS_SERVICE_IP' 'K8S_VER' 'HYPERKUBE_IMAGE_REPO' 'USE_CALICO' 'DOCKER_BOOTSTRAP_SOCK')

    if [ -f $ENV_FILE ]; then
        export $(cat $ENV_FILE | xargs)
    fi

    if [ -z $ADVERTISE_IP ]; then
        # export ADVERTISE_IP=$(ip -o -4 addr list eth1 | awk '{print $4}'| cut -d/ -f1 | head -1)
        export ADVERTISE_IP=$(ip -o -4 addr list $(route -n | awk '{if($1 == "0.0.0.0") print $8;}') | awk '{print $4}'| cut -d/ -f1 | head -1)
    fi

    for REQ in "${REQUIRED[@]}"; do
        if [ -z "$(eval echo \$$REQ)" ]; then
            echo "Missing required config value: ${REQ}"
            exit 1
        fi
    done
}

function config_flannel {
    echo "Waiting for etcd..."
    while true
    do
        IFS=',' read -ra ES <<< "$ETCD_ENDPOINTS"
        for ETCD in "${ES[@]}"; do
            echo "Trying: $ETCD"
            if [ -n "$(curl --silent "$ETCD/v2/machines")" ]; then
                local ACTIVE_ETCD=$ETCD
                break
            fi
            sleep 1
        done
        if [ -n "$ACTIVE_ETCD" ]; then
            break
        fi
    done
    RES=$(curl --silent -X PUT -d "value={\"Network\":\"$POD_NETWORK\",\"Backend\":{\"Type\":\"host-gw\"}}" "$ACTIVE_ETCD/v2/keys/coreos.com/network/config?prevExist=false")
    if [ -z "$(echo $RES | grep '"action":"create"')" ] && [ -z "$(echo $RES | grep 'Key already exists')" ]; then
        echo "Unexpected error configuring flannel pod network: $RES"
    fi
}


function config_master() {
  # all
  sed -i.back "s#\${HYPERKUBE_IMAGE_REPO}#${HYPERKUBE_IMAGE_REPO}#g" /etc/kubernetes/manifests/*.yaml
  sed -i.back "s#\$K8S_VER#${K8S_VER}#g" /etc/kubernetes/manifests/*.yaml

  # api-servers
  sed -i.back "s#\${ETCD_ENDPOINTS}#${ETCD_ENDPOINTS}#g" /etc/kubernetes/manifests/*.yaml
  sed -i.back "s#\${SERVICE_IP_RANGE}#${SERVICE_IP_RANGE}#g" /etc/kubernetes/manifests/*.yaml
  sed -i.back "s#\${ADVERTISE_IP}#${ADVERTISE_IP}#g" /etc/kubernetes/manifests/*.yaml

  # kube-controller-manager
  sed -i.back "s#\${POD_NETWORK}#${POD_NETWORK}#g" /etc/kubernetes/manifests/*.yaml

  rm -fr /etc/kubernetes/manifests/*.back
}

function config_addon() {
  # kube-dns-service
  sed -i.back "s#\${DNS_SERVICE_IP}#${DNS_SERVICE_IP}#g" /etc/kubernetes/addon/addon.yaml
  rm -fr /etc/kubernetes/manifests/*.back
}

# init env
init_config

# install docker
# kube::docker::install
# start bootstrap-docker
# kube::docker::init_bootstrap_docker
# kube::docker::start_bootstrap_docker

# config flannel parameter on etcd cluster
# config_flannel
# init flannel
# kube::flannel::init
# kube::flannel::start
# kube::flannel::export_subnet_env

# init docker
# kube::docker::init_docker
# kube::docker::start_docker
# kube::docker::pull_image

# config kubernetes master yaml
config_master
# config kubelet service env
kube::kubelet::compatible
kube::kubelet::install
kube::kubelet::init
kube::kubelet::start
# start_addons
echo "DONE"
