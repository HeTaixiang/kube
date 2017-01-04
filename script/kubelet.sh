#!/bin/bash
KUBELET_CMD="kubelet"

function kube::kubelet::install() {
  if [[ ! -f /"$KUBELET_CMD" ]]; then
    local CURRENT_PLATFORM=$(kube::helpers::host_platform)
    local ARCH=${ARCH:-${CURRENT_PLATFORM##*/}}
    curl -SL --retry 5 https://storage.googleapis.com/kubernetes-release/release/${K8S_VER}/bin/linux/${ARCH}/${KUBELET_CMD} > /${KUBELET_CMD}
  fi

  if [[ ! -f /${KUBELET_CMD} ]]; then
    kube::log::fatal "install kubelet failure, exit ..."
  fi
  chmod +x /${KUBELET_CMD}
}

function kube::kubelet::init() {
  local TEMPLATE=/etc/systemd/system/kubelet.service.d/kubelet.conf
  if [ ! -f $TEMPLATE ]; then
      echo "TEMPLATE: $TEMPLATE"
      mkdir -p $(dirname $TEMPLATE)

      cat <<EOF > $TEMPLATE
        [Service]
        Environment=CONTAINER_RUNTIME=${CONTAINER_RUNTIME}
        Environment=CONTROLLER_ENDPOINT=${CONTROLLER_ENDPOINT}
        Environment=ADVERTISE_IP=${ADVERTISE_IP}
        Environment=DNS_SERVICE_IP=${DNS_SERVICE_IP}
EOF
  fi
}

function kube::kubelet::start() {
  systemctl daemon-reload
  systemctl enable kubelet
  systemctl start kubelet
}

function kube::kubelet::compatible() {
  local kubelet=$(docker ps |grep kubelet |head -1)
  if [[ ! -z ${kubelet} ]]; then
    systemctl stop kubelet
    systemctl disable kubelet
    docker rm kubelet
    docker rm $(docker ps -aq)
  fi

  rm -fr /var/lib/kubelet/*
}
