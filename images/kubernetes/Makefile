REGISTRY=docker.zhimei360.com
GOLANG_VERSION=1.6
TEMP_DIR:=$(shell mktemp -d)
TAG:=$(shell curl -sSL "https://storage.googleapis.com/kubernetes-release/release/stable.txt")
ARCH?=amd64
BASEIMAGE?=${REGISTRY}/debian-iptables-${ARCH}:v4

.PHONY: download build push

all: push

download:
	curl -sSL --retry 5 https://storage.googleapis.com/kubernetes-release/release/$(TAG)/bin/linux/$(ARCH)/hyperkube > ${TEMP_DIR}/hyperkube
	chmod +x ${TEMP_DIR}/hyperkube

build: download
	# Copy the content in this dir to the temp dir
	cp ./* $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i.back "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile

	# And build the image
	docker build -t $(REGISTRY)/hyperkube-$(ARCH):$(TAG) $(TEMP_DIR)

	# delete temp dir
	rm -rf $(TEMP_DIR)
push: build
	docker push $(REGISTRY)/hyperkube-$(ARCH):$(TAG)
