REGISTRY_HOST ?= dev.registry.tanzu.vmware.com
REGISTRY_PROJECT ?= supply-chain-choreographer/cartographer-v2
CONTROLLER_VERSION ?= 0.0.1

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif
GOARCH=$(shell go env GOARCH)

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Acclerator Targets

.PHONY: test build-all-options build-default-options clean

test: clean build-all-options

build-all-options:
	./build-local.sh all-options

clean:
	rm -fr generated

ifndef ignore-not-found
  ignore-not-found = true
endif

##@ Catalog Targets

##Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Versions
KUSTOMIZE_VERSION ?= v4.5.7
YTT_VERSION ?= v0.45.4

## Tool Locations
KUSTOMIZE ?= $(LOCALBIN)/kustomize
YTT ?= $(LOCALBIN)/ytt

## Tool Installation
KUSTOMIZE_INSTALL_SCRIPT ?= "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"

.PHONY: kustomize
kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary. If wrong version is installed, it will be removed before downloading.

$(KUSTOMIZE): $(LOCALBIN)
	@if test -x $(LOCALBIN)/kustomize && ! $(LOCALBIN)/kustomize version | grep -q $(KUSTOMIZE_VERSION); then \
		echo "$(LOCALBIN)/kustomize version is not expected $(KUSTOMIZE_VERSION). Removing it before installing."; \
		rm -rf $(LOCALBIN)/kustomize; \
	fi
	test -s $(LOCALBIN)/kustomize || { curl -Ss $(KUSTOMIZE_INSTALL_SCRIPT) | bash -s -- $(subst v,,$(KUSTOMIZE_VERSION)) $(LOCALBIN); }

.PHONY: ytt
ytt: $(YTT)

$(YTT): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install github.com/vmware-tanzu/carvel-ytt/cmd/ytt@$(YTT_VERSION)

.PHONY: carvel
carvel: kustomize
	mkdir -p carvel
	echo $(KUSTOMIZE)
	$(KUSTOMIZE) build config/catalog > carvel/config.yaml

.PHONY: package
package: carvel ytt
	$(YTT) -f build-templates/kbld-config.yaml -f build-templates/values-schema.yaml -v build.registry_host=$(REGISTRY_HOST) -v build.registry_project=$(REGISTRY_PROJECT) > kbld-config.yaml
	$(YTT) -f build-templates/package-build.yml -f build-templates/values-schema.yaml -v build.registry_host=$(REGISTRY_HOST) -v build.registry_project=$(REGISTRY_PROJECT) > package-build.yml
	$(YTT) -f build-templates/package-resources.yml -f build-templates/values-schema.yaml > package-resources.yml

	kctrl package release -v $(CONTROLLER_VERSION) -y --debug

	@echo "-------------------------"
	cat kbld-config.yaml
	@echo "-------------------------"

	rm -f kbld-config.yaml
	rm -f package-build.yml
	rm -f package-resources.yml

