ARCH?=amd64
REGISTRY?=docker.zhimei360.com
TEMP_DIR:=$(shell mktemp -d)
TAG:=$(shell curl -sl "https://github.com/kubernetes/dashboard/releases/latest" | awk -F '"' '{print $$(NF-1)}' | awk -F '/' '{print $$NF}')

.PHONY: download build push

all: push
	https://github.com/kubernetes/dashboard/archive/v1.5.0.tar.gz

download:
	curl -sSL https://github.com/kubernetes/dashboard/archive/$(TAG).tar.gz -o $(TEMP_DIR)/$(TAG).tar.gz
	cd $(TEMP_DIR) && tar -xzf $(TAG).tar.gz -C $(TEMP_DIR) --strip-components=1 && rm $(TAG).tar.gz

build: download
	cp ./* $(TEMP_DIR)
	docker build -t $(REGISTRY)/etcd-$(ARCH):$(TAG) $(TEMP_DIR)
	rm -fr $(TEMP_DIR)

push: build
	docker push $(REGISTRY)/etcd-$(ARCH):$(TAG)
	gulp docker-image:canary
