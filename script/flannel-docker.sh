#!/bin/bash
export FLANNEL_IMAGE_REPO=${FLANNEL_IMAGE_REPO:-"docker.zhimei360.com/flannel"}
export FLANNEL_VER=${FLANNEL_VER:-"v0.6.2-amd64"}
export FLANNEL_NAME=${FLANNEL_NAME:-"flannel"}
export FLANNEL_RUNTIME_DIR=${FLANNEL_RUNTIME_DIR:-"/run/flannel"}
mkdir -p ${FLANNEL_RUNTIME_DIR}
TIMEOUT_FOR_SERVICES=60

function kube::flannel::init() {
  local TEMPLATE=/etc/systemd/system/flannel.service.d/flannel_docker.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)

    cat <<EOF > $TEMPLATE
      [Service]
      Environment=FLANNEL_RUNTIME_DIR=${FLANNEL_RUNTIME_DIR}
      Environment=DOCKER_BOOTSTRAP_SOCK=${DOCKER_BOOTSTRAP_SOCK}
      Environment=FLANNEL_NAME=${FLANNEL_NAME}
      Environment=FLANNEL_IMAGE_REPO=${FLANNEL_IMAGE_REPO}
      Environment=FLANNEL_VER=${FLANNEL_VER}
EOF
  fi

  local TEMPLATE=/etc/systemd/system/flannel.service.d/flannel.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)

    cat <<EOF > $TEMPLATE
      [Service]
      Environment=ETCD_ENDPOINTS=${ETCD_ENDPOINTS}
      Environment=ADVERTISE_IP=${ADVERTISE_IP}
EOF
  fi
}

function kube::flannel::export_subnet_env() {
  local SECONDS=0
  while [[ ! -f ${FLANNEL_RUNTIME_DIR}/subnet.env ]]; do
    kube::log::status "wait $SECONDS"
    SECONDS=$[SECONDS + 1]
    if [[ ${SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
      kube::log::fatal "flannel failed to start. Exiting..."
    fi
    sleep 1
  done
  kube::log::status "flannel success to start"
  export $(cat ${FLANNEL_RUNTIME_DIR}/subnet.env | xargs)
}

function kube::flannel::start() {
  systemctl daemon-reload
  systemctl enable flannel
  systemctl start flannel

}
