
# 🧁 Welcome to the Toy Shop App! (Kind Edition)

This is your magical Toy Shop where:

* 🏃 You can run it on your own computer (with Docker + Kind!)
* 🤖 Azure DevOps robots help build and test everything
* ☁️ The Toy Shop goes live in the cloud (AKS + Flux + Helm)

Let’s go step-by-step like a fun adventure! 🧭🎒

---

## 🛠️ 1. How to Run the Toy Shop on Your Computer (Locally)

> So you can play with your toy shop on your computer before going to the cloud!

### 🧰 Step 1: Prerequisites

Make sure you have these installed:

* [Docker](https://www.docker.com/)
* [Kind](https://kind.sigs.k8s.io/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/)
* [Helm](https://helm.sh/)
* [Make](https://www.gnu.org/software/make/)

### ☸️ Step 2: Run with Kind + Helm

> Like building a mini cloud on your own laptop!

#### 🏗️ Step 1: Create a Cluster

```bash
kind create cluster --name toyshop
```

#### 🐳 Step 2: Install your helm chart

```bash
kubectl create namespace toy-shop
helm install toy-shop ./charts -n toy-shop
```

#### 🗂️ Step 3: Check all the resources

```bash
kubectl get all -n toy-shop
```

#### 🔍 Step 4: See the frontend

```bash
kubectl port-forward svc/store-front 3000:80 -n toy-shop
```

Visit [http://localhost:3000](http://localhost:3000)

You’re now running your own Toy Shop in Kind! 🏰✨

---

## Alternative

I've wrapped all these commands in a make file that you just need to run in bash!  🏰✨

```bash
make kind-up         # Create local Kubernetes cluster with Kind
make helm-install    # Install helm chart
make check-all-resources       # Check resources in kuberentes
make see-frontend    # See the front end
```

Then go to [http://localhost:3000](http://localhost:3000) to see your frontend! 🎠

---
## 🔁 2. How to Configure and Run the CI/CD Pipeline (Azure DevOps Robots 🤖)

> Robots that watch your code, build it, test it, and ship it!

### 🧼 Before You Start

* GitHub repo created ✅
* Azure DevOps project ✅
* Azure Service Principal setup ✅

---

### 📋 Steps:

1. Create `.azure-pipelines.yml` in your repo:

2. Push this file to GitHub.

3. In Azure DevOps, create a pipeline → connect to your GitHub → it auto-runs! 🎉

---

## ☁️ 3. How to Deploy to Cloud Kubernetes (AKS)

### 🧱 Step 1: Use Terraform to Create AKS + ACR

Install [Terraform](https://developer.hashicorp.com/terraform/downloads), then:

```bash
terraform init
terraform apply
```

This creates:

* AKS cluster 🌩️
* ACR for container images 📦

---

### 📦 Step 2: Set Up Helm Chart

Your chart (`charts/`) should have:

* ✅ `values.yaml` with frontend/backend image configs
* ✅ `deployment.yaml` with CPU/memory resource limits
* ✅ `networkpolicy.yaml` to protect services
* ✅ `ingress.yaml` to open the frontend to the internet

---

### 🔄 Step 3: Connect GitHub to the Cluster with Flux

Install [Flux CLI](https://fluxcd.io/):

```bash
brew install flux
```

Then run:

```bash
flux bootstrap github \
  --owner=your-github-username \
  --repository=your-repository-name \
  --branch=main \
  --path=clusters/prod \
  --personal
```

In `clusters/prod`, add:

* `source.yaml` → points to your code repo
* `helmrelease.yaml` → tells the cluster to install from your Helm chart

Flux keeps your cluster synced with GitHub! 🪄✨

---

```bash
PS: All these steps are run in the pipeline to make deployment seamless
```
## 🎉 You Did It!
