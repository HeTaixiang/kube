#!/bin/bash
export ETCD_IMAGE_REPO="docker.zhimei360.com/etcd-amd64"
export ETCD_VER="v3.0.15"
export ETCD_DATA_DIR="/var/lib/etcd/"
mkdir -p ${ETCD_DATA_DIR}

function kube::etcd::export_etcd_env() {
  export $(cat ${ETCD_DATA_DIR}/etcd.env | xargs)
}

function kube::etcd::init() {
  local TEMPLATE=/etc/systemd/system/etcd.service.d/etcd.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)

    cat <<EOF > $TEMPLATE
    [Service]
    Environment=ETCD_NAME=${NAME}
    Environment=ETCD_LISTEN_PEER_URLS=http://${IP}:2380
    Environment=ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
    Environment=ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${IP}:2380
    Environment=ETCD_INITIAL_CLUSTER=$INIT_ETCD_CLUSTER
    Environment=ETCD_ADVERTISE_CLIENT_URLS=http://${IP}:2379
EOF
  fi

  local TEMPLATE=/etc/systemd/system/etcd.service.d/etcd-docker.conf
  if [[ ! -f $TEMPLATE ]]; then
    echo "TEMPLATE: $TEMPLATE"
    mkdir -p $(dirname $TEMPLATE)

    cat <<EOF > $TEMPLATE
    [Service]
    Environment=ETCD_DATA_DIR=${ETCD_DATA_DIR}
    Environment=ETCD_NAME=${NAME}
    Environment=ETCD_IMAGE_REPO=${ETCD_IMAGE_REPO}
    Environment=ETCD_VER=${ETCD_VER}
EOF
  fi
}

function kube::etcd::start() {
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
}
