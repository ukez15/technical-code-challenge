IMAGE_VERSION ?= 0.0.1-beta
RANDOM := $(shell bash -c 'echo $$RANDOM')
RG_NAME ?= toyshop-rg
ACR_NAME ?= toyshopacr12345
AKS_NAME ?= toyshop-aks
BUILD_ORDER_SERVICE ?= false
BUILD_PRODUCT_SERVICE ?= false
BUILD_STORE_FRONT ?= false

.PHONY: local 
local: kind-up helm-install check-all-resources see-frontend ## do a helm install and and deploy to kind cluster

.PHONY: teardown 
local: kind-down ## do a kind delete to remove the local env

.PHONY: azure-pipeline
azure: get-azure-resources deploy-azure ## Provision Azure Resources, build all container images, push images to Azure Container Registry, and deploy to AKS cluster

##@ Provision Azure Resources
.PHONY: get-azure-resources
get-azure-resources: ## Get provisioned Azure resources, build or import images to ACR
	@echo "Getting the Azure Resources"
	@az aks update -n $(AKS_NAME) -g $(RG_NAME) --attach-acr $(ACR_NAME)
	@az aks get-credentials -n $(AKS_NAME) -g $(RG_NAME)

	@echo "Checking order-service:$(IMAGE_VERSION)"
	@if ! az acr repository show-tags --name $(ACR_NAME) --repository order-service --query "[?@=='$(IMAGE_VERSION)']" -o tsv | grep -q $(IMAGE_VERSION); then \
		echo "Building or importing order-service:$(IMAGE_VERSION)..."; \
		if [ "$(BUILD_ORDER_SERVICE)" = true ]; then \
			az acr build -r $(ACR_NAME) -t order-service:$(IMAGE_VERSION) ./src/order-service; \
		else \
			az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/order-service:latest --image order-service:$(IMAGE_VERSION); \
		fi; \
	else \
		echo "order-service:$(IMAGE_VERSION) already exists. Skipping."; \
	fi

	@echo "Checking product-service:$(IMAGE_VERSION)"
	@if ! az acr repository show-tags --name $(ACR_NAME) --repository product-service --query "[?@=='$(IMAGE_VERSION)']" -o tsv | grep -q $(IMAGE_VERSION); then \
		echo "Building or importing product-service:$(IMAGE_VERSION)..."; \
		if [ "$(BUILD_PRODUCT_SERVICE)" = true ]; then \
			az acr build -r $(ACR_NAME) -t product-service:$(IMAGE_VERSION) ./src/product-service; \
		else \
			az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/product-service:latest --image product-service:$(IMAGE_VERSION); \
		fi; \
	else \
		echo "product-service:$(IMAGE_VERSION) already exists. Skipping."; \
	fi

	@echo "Checking store-front:$(IMAGE_VERSION)"
	@if ! az acr repository show-tags --name $(ACR_NAME) --repository store-front --query "[?@=='$(IMAGE_VERSION)']" -o tsv | grep -q $(IMAGE_VERSION); then \
		echo "Building or importing store-front:$(IMAGE_VERSION)..."; \
		if [ "$(BUILD_STORE_FRONT)" = true ]; then \
			az acr build -r $(ACR_NAME) -t store-front:$(IMAGE_VERSION) ./src/store-front; \
		else \
			az acr import -n $(ACR_NAME) --source ghcr.io/azure-samples/aks-store-demo/store-front:latest --image store-front:$(IMAGE_VERSION); \
		fi; \
	else \
		echo "store-front:$(IMAGE_VERSION) already exists. Skipping."; \
	fi


.PHONY: deploy-azure
deploy-azure: ## Deploy to AKS cluster
	@echo "Deploying to AKS using Helm..."
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

.PHONY: kind-down
kind-down: ##tear down everything locally
	kind delete clusters toyshop