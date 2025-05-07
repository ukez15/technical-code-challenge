
# 🧁 Welcome to the Toy Shop App! (Kind Edition)

This is your magical Toy Shop where:

* 🏃 You can run it on your own computer (with Docker + Kind!)
* 🤖 Azure DevOps robots help build and test everything
* ☁️ The Toy Shop goes live in the cloud (AKS + Flux + Helm)

Let’s go step-by-step like a fun adventure! 🧭🎒

---

## 🛠️ 1. How to Run the Toy Shop on Your Computer (Locally)

### 📦 Option 1: Use Docker (Fast and Simple)

1. 🐳 Make sure [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed.

2. Build your app like this:

```bash
docker build -t toyshop-frontend ./frontend
docker build -t toyshop-backend ./backend
```

3. Run the apps:

```bash
docker run -p 3000:3000 toyshop-frontend
docker run -p 8000:8000 toyshop-backend
```

Visit:

* 🖥️ Frontend → [http://localhost:3000](http://localhost:3000)
* 📡 Backend → [http://localhost:8000](http://localhost:8000)

---
```bash
Note: This option is only available if you have the app source code built on your machine using docker.
For our purpose, we start with option 2.
```


### ☸️ Option 2: Use Kind (Kubernetes in Docker!)

> Like building a mini cloud on your own laptop!

#### 🧰 Step 1: Install [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

```bash
brew install kind      # (macOS)
```

#### 🏗️ Step 2: Create a Cluster

```bash
kind create cluster --name toyshop
```

#### 🐳 Step 3: Install your helm chart

```bash
kubectl create namespace toy-shop
helm install toy-shop ./charts -n toy-shop
# kind load docker-image toyshop-frontend --name toyshop
# kind load docker-image toyshop-backend --name toyshop
```

#### 🗂️ Step 4: Check all the resources

```bash
kubectl get all -n toy-shop

```

#### 🔍 Step 5: See the frontend

```bash
kubectl port-forward svc/store-front 3000:80 -n toy-shop
```

Visit [http://localhost:3000](http://localhost:3000)

You’re now running your own Toy Shop in Kind! 🏰✨

---

## 🔁 2. How to Configure and Run the CI/CD Pipeline (Azure DevOps Robots 🤖)

> Robots that watch your code, build it, test it, and ship it!

### 🧼 Before You Start

* GitHub repo created ✅
* Azure DevOps project ✅
* Azure Container Registry (ACR) set up ✅
* Dockerfiles ready ✅

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
  --repository=aks-toyshop-flux \
  --branch=main \
  --path=clusters/prod \
  --personal
```

In `clusters/prod`, add:

* `source.yaml` → points to your code repo
* `helmrelease.yaml` → tells the cluster to install from your Helm chart

Flux keeps your cluster synced with GitHub! 🪄✨

---

## 🎉 You Did It!
