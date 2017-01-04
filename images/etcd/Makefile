ARCH?=amd64
REGISTRY?=docker.zhimei360.com
TEMP_DIR:=$(shell mktemp -d)
TAG:=$(shell curl -sl "https://github.com/coreos/etcd/releases/latest" | awk -F '"' '{print $$(NF-1)}' | awk -F '/' '{print $$NF}')

.PHONY: download build push

all: push

download:
	curl -sSL https://github.com/coreos/etcd/releases/download/$(TAG)/etcd-$(TAG)-linux-amd64.tar.gz -o $(TEMP_DIR)/etcd-$(TAG)-linux-amd64.tar.gz
	cd $(TEMP_DIR) && tar -xvzf etcd-$(TAG)-linux-amd64.tar.gz -C $(TEMP_DIR) --strip-components=1 && rm etcd-$(TAG)-linux-amd64.tar.gz

build: download
	cp ./* $(TEMP_DIR)
	docker build -t $(REGISTRY)/etcd-$(ARCH):$(TAG) $(TEMP_DIR)
	rm -fr $(TEMP_DIR)

push: build
	docker push $(REGISTRY)/etcd-$(ARCH):$(TAG)
