ARCH?=amd64
REGISTRY?=docker.zhimei360.com
TEMP_DIR:=$(shell echo "$$PWD/build")
TAG:=$(shell curl -sl "https://github.com/kubernetes/heapster/releases/latest" | awk -F '"' '{print $$(NF-1)}' | awk -F '/' '{print $$NF}')
.PHONY: download build push grafana influxdb clean

all: push

download:
	@if [ ! -d $(TEMP_DIR) ];then \
		mkdir -p $(TEMP_DIR); \
		curl -sSL https://github.com/kubernetes/heapster/archive/$(TAG).tar.gz -o $(TEMP_DIR)/$(TAG).tar.gz; \
		cd $(TEMP_DIR) && tar -xzf $(TAG).tar.gz -C $(TEMP_DIR) --strip-components=1 && rm $(TAG).tar.gz; \
	fi

build: download
	docker run --rm -ti -v $(TEMP_DIR):/go/src/k8s.io/heapster golang:1.7-alpine sh -c \
		'apk add make git --no-cache && cd src/k8s.io/heapster && make build'
	cp $(TEMP_DIR)/heapster $(TEMP_DIR)/deploy/docker/heapster && cp $(TEMP_DIR)/eventer $(TEMP_DIR)/deploy/docker/eventer
	docker build -t $(REGISTRY)/heapster-$(ARCH):$(TAG) $(TEMP_DIR)/deploy/docker/

grafana: download
	docker build -t $(REGISTRY)/heapster_grafana-$(ARCH):$(TAG) $(TEMP_DIR)/grafana/

influxdb: download
	docker build -t $(REGISTRY)/heapster_influxdb-$(ARCH):$(TAG) $(TEMP_DIR)/influxdb/

push: build
	docker push $(REGISTRY)/heapster-$(ARCH):$(TAG)

clean:
	rm -fr $(TEMP_DIR)
