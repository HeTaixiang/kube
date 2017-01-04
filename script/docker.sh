#!/bin/bash
set -e

# parameter require
#
# DOCKER_BOOTSTRAP_SOCK
# FLANNEL_MTU
# FLANNEL_SUBNET

function kube::docker::install() {
  if ! kube::helpers::command_exists docker; then
    curl -fsSL https://get.docker.com/|sh
  fi

}

function kube::docker::init_bootstrap_docker() {
  local TEMPLATE=/etc/systemd/system/bootstrap-docker.service.d/bootstrap-docker.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)

    cat <<EOF > $TEMPLATE
      [Service]
      Environment=DOCKER_BOOTSTRAP_SOCK=${DOCKER_BOOTSTRAP_SOCK}
EOF
  fi
}

function kube::docker::start_bootstrap_docker() {
  systemctl daemon-reload
  systemctl enable bootstrap-docker
  systemctl start bootstrap-docker
}

function kube::docker::init_docker() {
  local TEMPLATE=/etc/systemd/system/docker.service.d/options.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)
  else
    kube::log::status "delete exist file and for update"
    rm -f $TEMPLATE
  fi

  cat <<EOF > $TEMPLATE
    [Unit]
    After=flannel.service
    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd --mtu=${FLANNEL_MTU} --bip=${FLANNEL_SUBNET}
EOF
}

function kube::docker::start_docker() {
  systemctl daemon-reload
  systemctl enable docker
  systemctl start docker

}

function kube::docker::pull_image() {
  # pull docker.zhimei360.com/pause-amd64:3.0
  docker pull docker.zhimei360.com/pause-amd64:3.0
  docker pull docker.zhimei360.com/hyperkube-amd64:${K8S_VER}
}
