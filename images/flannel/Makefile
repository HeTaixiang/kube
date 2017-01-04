.PHONY: download envcheck preprocess clean build docker-push release docker-push-all

REGISTRY?=docker.zhimei360.com
ARCH?=amd64
TEMP_DIR:=$(shell echo "$$PWD/build")
TAG:=$(shell curl -sl "https://github.com/coreos/flannel/releases/latest" | awk -F '"' '{print $$(NF-1)}' | awk -F '/' '{print $$NF}')
KUBE_CROSS_IMAGE=kube-cross
KUBE_CROSS_TAG:=$(shell docker images --format "{{.Repository}}:{{.Tag}}" | grep "$(KUBE_CROSS_IMAGE)" | head -1 | cut -d ":" -f 2)
KUBE_CROSS_REPOSITORY=git@github.com:HeTaixiang/kube-cross.git

ifeq ($(KUBE_CROSS_TAG)x, x)
	KUBE_CROSS_VERSION:=$(shell if [ ! -d ./kube-cross ]; then git clone $(KUBE_CROSS_REPOSITORY); fi && cat ./kube-cross/VERSION)
else
  KUBE_CROSS_VERSION:=$(KUBE_CROSS_TAG)
endif

all: docker-push-all

download:
	curl -sSL https://github.com/coreos/flannel/archive/$(TAG).tar.gz -o $(TEMP_DIR)/$(TAG).tar.gz
	cd $(TEMP_DIR) && tar -xvzf $(TAG).tar.gz -C $(TEMP_DIR) --strip-components=1 && rm $(TAG).tar.gz

envcheck:
	# check KUBE_CROSS_TAG Docker is in local and build env
	@if [ -z "$(KUBE_CROSS_TAG)" ]; then cd kube-cross && make; fi
	@if [ ! -d "$(TEMP_DIR)" ]; then mkdir $(TEMP_DIR); fi

clean:
	@if [ -d ./kube-cross ];then rm -fr ./kube-cross; fi

preprocess: envcheck download
	# replace REGISTRY and kube-cross version
	cd $(TEMP_DIR) && sed -i.back "s#quay.io/coreos#$(REGISTRY)#g" Makefile
	cd $(TEMP_DIR) && sed -i.back "s#gcr.io/google_containers#$(REGISTRY)#g" Makefile
	cd $(TEMP_DIR) && sed -i.back "s#$$(grep "^KUBE_CROSS_TAG" Makefile | cut -d "=" -f 2)#$(KUBE_CROSS_VERSION)#" Makefile
	cd $(TEMP_DIR) && sed -i.back "s#$$(grep "^TAG?=" Makefile | cut -d "=" -f 2)#$(TAG)#" Makefile

build: preprocess
	cd $(TEMP_DIR) && make dist/flanneld-$(TAG)-$(ARCH).docker
	rm -fr $(TEMP_DIR)

docker-push: preprocess
	cd $(TEMP_DIR) && make docker-push TAG=$(TAG) ARCH=$(ARCH)
	rm -fr $(TEMP_DIR)

release: preprocess
	cd $(TEMP_DIR) && make release
	rm -fr $(TEMP_DIR)

docker-push-all: preprocess
	cd $(TEMP_DIR) && make docker-push-all
	rm -fr $(TEMP_DIR)
