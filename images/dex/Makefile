.PHONY: download envcheck preprocess clean  docker-push

REGISTRY?=docker.zhimei360.com
ARCH?=amd64
TEMP_DIR:=$(shell echo "$$PWD/build")
TAG:=$(shell curl -sl "https://github.com/coreos/dex/releases/latest" | awk -F '"' '{print $$(NF-1)}' | awk -F '/' '{print $$NF}')
PROJ=dex
ORG_PATH=github.com/coreos
REPO_PATH=$(ORG_PATH)/$(PROJ)
LD_FLAGS="-w -X $(REPO_PATH)/version.Version=$(TAG)"


all: docker-push

download:
	curl -sSL https://github.com/coreos/dex/archive/$(TAG).tar.gz -o $(TEMP_DIR)/$(TAG).tar.gz
	@cd $(TEMP_DIR) && tar -xvzf $(TAG).tar.gz -C $(TEMP_DIR) --strip-components=1 && rm $(TAG).tar.gz

envcheck:
	@mkdir -p $(TEMP_DIR) && mkdir -p $(TEMP_DIR)/dist

clean:
	@if [ -d $(TEMP_DIR) ];then rm -fr $(TEMP_DIR); fi

preprocess: envcheck download
	@echo "process before build ..."
	@cp -f Dockerfile Makefile $(TEMP_DIR)

dist/dex-$(ARCH): preprocess
	docker run -it --rm \
	  -v $(TEMP_DIR):/go/src/github.com/coreos/dex \
    -v $(TEMP_DIR)/dist:/go/src/github.com/coreos/dex/dist \
    golang:1.7.4-alpine /bin/sh -c \
			'apk add --no-cache --update alpine-sdk && \
			cd /go/src/github.com/coreos/dex && \
			go build -o ./dist/dex -v -ldflags $(LD_FLAGS) ./cmd/dex'

docker-$(ARCH): dist/dex-$(ARCH)
	cd $(TEMP_DIR) && docker build -t $(REGISTRY)/dex-$(ARCH):$(TAG) .

docker-push: docker-$(ARCH)
	docker push $(REGISTRY)/dex-$(ARCH):$(TAG)
	rm -fr $(TEMP_DIR)
