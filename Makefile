IMAGE_VERSION ?= 0.0.1-beta
RANDOM := $(shell bash -c 'echo $$RANDOM')
LOC_NAME ?= eastus
RG_NAME ?= toyshop-rg
ACR_NAME ?= toyshopacr12345
AKS_NAME ?= toyshop-aks
BUILD_ORDER_SERVICE ?= false
BUILD_MAKELINE_SERVICE ?= false
BUILD_PRODUCT_SERVICE ?= false
BUILD_STORE_FRONT ?= false

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# .PHONY: local 
# local: build load kustomize deploy ## Build all container images, load images into kind cluster, and deploy to kind cluster

.PHONY: azure
azure: get-azure-resources deploy-azure ## Provision Azure Resources, build all container images, push images to Azure Container Registry, and deploy to AKS cluster

##@ Build images

# .PHONY: build
# build: ./src/order-service/Dockerfile \
# 	./src/makeline-service/Dockerfile \
# 	./src/product-service/Dockerfile \
# 	./src/store-front/Dockerfile \
# 	## Build all images
# 	@docker build -t order-service:$(IMAGE_VERSION) ./src/order-service
# 	@docker build -t makeline-service:$(IMAGE_VERSION) ./src/makeline-service
# 	@docker build -t product-service:$(IMAGE_VERSION) ./src/product-service
# 	@docker build -t store-front:$(IMAGE_VERSION) ./src/store-front

##@ Provision Azure Resources

.PHONY: get-azure-resources
get-azure-resources: ## Get Provisioned Azure Resources and push docker images to ACR
	@echo "Getting the Azure Resources"
	@az aks update -n $(AKS_NAME) -g $(RG_NAME) --attach-acr $(ACR_NAME)
	@az aks get-credentials -n $(AKS_NAME) -g $(RG_NAME)

	@if [ "$(BUILD_ORDER_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t order-service:$(IMAGE_VERSION) ./src/order-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/order-service:latest --image order-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_MAKELINE_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t makeline-service:$(IMAGE_VERSION) ./src/makeline-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/makeline-service:latest --image makeline-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_PRODUCT_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t product-service:$(IMAGE_VERSION) ./src/product-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/product-service:latest --image product-service:$(IMAGE_VERSION); \
	fi

	@if [ "$(BUILD_STORE_FRONT)" = true ]; then \
		az acr build -r $(ACR_NAME) -t store-front:$(IMAGE_VERSION) ./src/store-front; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/store-front:latest --image store-front:$(IMAGE_VERSION); \
	fi

.PHONY: deploy-azure
deploy-azure: kustomize toy-store-all-in-one.yaml ## Deploy to AKS cluster
	@$(KUSTOMIZE) create --resources toy-store-all-in-one.yaml
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=$(ACR_NAME).azurecr.io/order-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=$(ACR_NAME).azurecr.io/makeline-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=$(ACR_NAME).azurecr.io/product-service:$(IMAGE_VERSION)
	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=$(ACR_NAME).azurecr.io/store-front:$(IMAGE_VERSION)
	@kubectl apply -k .


.PHONY: clean-azure
clean-azure: ## Delete kind cluster and kustomization.yaml
	@az group delete -n $(RG_NAME) -y --no-wait
	@rm -f kustomization.yaml
	@rm -rf $(LOCALBIN)

# ##@ Deploy to kind cluster

# .PHONY: load
# load: build kind ## Load all locally built containers into kind cluster
# 	@$(KIND) load docker-image \
# 		order-service:$(IMAGE_VERSION) \
# 		makeline-service:$(IMAGE_VERSION) \
# 		product-service:$(IMAGE_VERSION) \
# 		store-front:$(IMAGE_VERSION) 

# .PHONY: manifest ## Create kustomization.yaml and set image versions to locally built images
# manifest: kustomize aks-store-all-in-one.yaml
# 	@$(KUSTOMIZE) create --resources aks-store-all-in-one.yaml
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=order-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=makeline-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=product-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=store-front:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-admin=store-admin:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-customer=virtual-customer:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/virtual-worker=virtual-worker:$(IMAGE_VERSION)

# .PHONY: deploy
# deploy: manifest ## Deploy to cluster
# 	@kubectl apply -k .

# .PHONY: clean 
# clean: ## Delete kind cluster and kustomization.yaml
# 	@if [ `kind get clusters | wc -l` -gt 0 ]; then \
# 		kind delete cluster; \
# 	fi
# 	@rm -f kustomization.yaml
# 	@rm -rf $(LOCALBIN)

##@ Build Dependencies

# LOCALBIN ?= $(shell pwd)/bin
# $(LOCALBIN):
# 	@mkdir -p $(LOCALBIN)

# # tools
# KUSTOMIZE ?= $(LOCALBIN)/kustomize
# ENVTEST ?= $(LOCALBIN)/setup-envtest
# KIND ?= $(LOCALBIN)/kind

# # tool versions
# KUSTOMIZE_VERSION ?= v5.4.3
# KIND_VERSION ?= v0.23.0

# # kustomize 
# KUSTOMIZE_INSTALL_SCRIPT ?= "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
# .PHONY: kustomize
# kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary. If wrong version is installed, it will be removed before downloading.
# $(KUSTOMIZE): $(LOCALBIN)
# 	@if test -x $(LOCALBIN)/kustomize && ! $(LOCALBIN)/kustomize version | grep -q $(KUSTOMIZE_VERSION); then \
# 		echo "$(LOCALBIN)/kustomize version is not expected $(KUSTOMIZE_VERSION). Removing it before installing."; \
# 		rm -rf $(LOCALBIN)/kustomize; \
# 	fi
# 	@test -s $(LOCALBIN)/kustomize || { curl -Ss $(KUSTOMIZE_INSTALL_SCRIPT) | bash -s -- $(subst v,,$(KUSTOMIZE_VERSION)) $(LOCALBIN); }

# .PHONY: envtest
# envtest: $(ENVTEST) ## Download envtest-setup locally if necessary.
# $(ENVTEST): $(LOCALBIN)
# 	@test -s $(LOCALBIN)/setup-envtest || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

# .PHONY: kind
# kind: $(KIND) ## Download kind locally if necessary and create a new cluster. If wrong version is installed, it will be overwritten.
# $(KIND): $(LOCALBIN)
# 	@test -s $(LOCALBIN)/kind && $(LOCALBIN)/kind --version | grep -q $(KIND_VERSION) || \
# 	GOBIN=$(LOCALBIN) go install sigs.k8s.io/kind@$(KIND_VERSION)
# 	@if [ `$(KIND) get clusters | wc -l` -eq 0 ]; then \
# 		$(KIND) create cluster; \
# 	fi