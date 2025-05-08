IMAGE_VERSION ?= 0.0.1-beta
RANDOM := $(shell bash -c 'echo $$RANDOM')
LOC_NAME ?= eastus
RG_NAME ?= toyshop-rg
ACR_NAME ?= toyshopacr12345
AKS_NAME ?= toyshop-aks
BUILD_ORDER_SERVICE ?= false
BUILD_PRODUCT_SERVICE ?= false
BUILD_STORE_FRONT ?= false

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: local 
local: kind-up helm-install check-all-resources see-frontend ## do a helm install and and deploy to kind cluster

.PHONY: azure
azure: get-azure-resources deploy-azure ## Provision Azure Resources, build all container images, push images to Azure Container Registry, and deploy to AKS cluster

##@ Provision Azure Resources

.PHONY: get-azure-resources
get-azure-resources: ## Get Provisioned Azure Resources, builds docker images and push docker images to ACR
	@echo "Getting the Azure Resources"
	@az aks update -n $(AKS_NAME) -g $(RG_NAME) --attach-acr $(ACR_NAME)
	@az aks get-credentials -n $(AKS_NAME) -g $(RG_NAME)

	@if [ "$(BUILD_ORDER_SERVICE)" = true ]; then \
		az acr build -r $(ACR_NAME) -t order-service:$(IMAGE_VERSION) ./src/order-service; \
	else \
		az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/order-service:latest --image order-service:$(IMAGE_VERSION); \
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
# deploy-azure: kustomize toy-store-all-in-one.yaml ## Deploy to AKS cluster
# 	@$(KUSTOMIZE) create --resources toy-store-all-in-one.yaml
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/order-service=$(ACR_NAME).azurecr.io/order-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/makeline-service=$(ACR_NAME).azurecr.io/makeline-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/product-service=$(ACR_NAME).azurecr.io/product-service:$(IMAGE_VERSION)
# 	@$(KUSTOMIZE) edit set image ghcr.io/azure-samples/aks-store-demo/store-front=$(ACR_NAME).azurecr.io/store-front:$(IMAGE_VERSION)
# 	@kubectl apply -k .
	@echo "🚀 Deploying to AKS using Helm..."
	@az aks get-credentials -n $(AKS_NAME) -g $(RG_NAME)
	@helm upgrade --install toy-shop ./chart \
		--set orderService.image.repository=$(ACR_NAME).azurecr.io/order-service:$(IMAGE_VERSION) \
		--set productService.image.repository=$(ACR_NAME).azurecr.io/product-service:$(IMAGE_VERSION) \
		--set storeFront.image.repository=$(ACR_NAME).azurecr.io/store-front:$(IMAGE_VERSION) \
		--namespace toy-shop \
		--create-namespace


.PHONY: clean-azure
clean-azure: ## Delete kind cluster and kustomization.yaml
	@az group delete -n $(RG_NAME) -y --no-wait
	@rm -f kustomization.yaml
	@rm -rf $(LOCALBIN)

.PHONY: kind-up
kind-up: ##create kind cluster
	kind create cluster --name toyshop

.PHONY: helm-install
helm-install: ##install helm chart
	kubectl create namespace toy-shop
	helm install toy-shop ./charts -n toy-shop

.PHONY: check-all-resources
check-all-resources: ##check resources in kuberentes
	kubectl get all -n toy-shop

.PHONY: see-frontend
see-frontend: ##see the front end
	sleep 90
	kubectl port-forward svc/store-front 3000:80 -n toy-shop