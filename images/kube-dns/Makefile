REGISTRY=docker.zhimei360.com
GOLANG_VERSION=1.6
TEMP_DIR:=$(shell mktemp -d)
TAG:=$(shell curl -sSL "https://storage.googleapis.com/kubernetes-release/release/stable.txt")
ARCH?=amd64

ifeq ($(ARCH),amd64)
	BASEIMAGE?=busybox
endif
ifeq ($(ARCH),arm)
	BASEIMAGE?=armel/busybox
endif
ifeq ($(ARCH),arm64)
	BASEIMAGE?=aarch64/busybox
endif
ifeq ($(ARCH),ppc64le)
	BASEIMAGE?=ppc64le/busybox
endif

.PHONY: download build push

all: push

download:
	curl -sSL --retry 5 https://storage.googleapis.com/kubernetes-release/release/$(TAG)/bin/linux/$(ARCH)/kube-dns > ${TEMP_DIR}/kube-dns
	chmod +x ${TEMP_DIR}/kube-dns

build: download
	# Copy the content in this dir to the temp dir
	cp ./Dockerfile $(TEMP_DIR)
	cd $(TEMP_DIR) && sed -i.back "s|BASEIMAGE|$(BASEIMAGE)|g" Dockerfile

	# And build the image
	docker build -t $(REGISTRY)/kubedns-$(ARCH):$(TAG) $(TEMP_DIR)

	# delete temp dir
	rm -rf $(TEMP_DIR)
push: build
	docker push $(REGISTRY)/kubedns-$(ARCH):$(TAG)
