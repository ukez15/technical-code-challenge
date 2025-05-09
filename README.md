# 🧁 Welcome to the Toy Shop App! (Kind & Cloud Edition)

This is your magical Toy Shop where:

* 🏃 You can run it on your own computer (with Docker + Kind!)
* 🤖 Azure DevOps robots help build, test, and deploy automatically
* ☁️ The Toy Shop goes live in the cloud (AKS + Flux + Helm)
* 🔄 And the whole system is smart and **resilient** — it avoids breaking if things already exist!

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

## Alternative (The Easy Way!)

You can also run all of the above with these one-liner make commands:

```bash
make kind-up            # Create local Kubernetes cluster with Kind
make helm-install       # Install Helm chart
make check-all-resources  # Check resources in Kubernetes
make see-frontend       # Open frontend in browser
```

Then go to [http://localhost:3000](http://localhost:3000) to see your frontend! 🎠

---

## 🔁 2. How to Configure and Run the CI/CD Pipeline (Azure DevOps Robots 🤖)

> Robots that watch your code, build it, test it, and ship it!

### 🧼 Before You Start

* GitHub repo created ✅
* Azure DevOps project ✅
* Azure Service connection setup ✅
* Variable group called `terraform-auth` ✅
* GitHub Personal Access Token (PAT) stored as secret variable `GITHUB_TOKEN` ✅
  * Must have **repo** and **workflow** scopes

---

### 📋 Pipeline Overview

The Azure pipeline does everything:

1. Logs in to Azure
2. Checks if infrastructure (RG, ACR, AKS) already exists
   * If yes: it **imports** them into Terraform
   * If no: it **creates** them from scratch
3. Checks if Docker images are already in ACR
   * If yes: it **skips building**
   * If no: it **builds/imports only missing images**
4. Deploys using Helm to AKS
5. Boots up Flux to keep AKS synced with your GitHub repo
   * If Flux is **already installed**, it skips bootstrapping automatically

> ✅ **The pipeline is fully resilient** — no unnecessary duplication, no errors from already existing stuff, and repeatable runs are safe!

To run it:

1. Create `.azure-pipelines.yml` in your repo
2. Push it to GitHub
3. In Azure DevOps → create pipeline → link GitHub → done!

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

> In the pipeline, Terraform is smart: it imports existing infra when needed and only creates new stuff.

---

### 📦 Step 2: Set Up Helm Chart

Your chart (`charts/`) should have:

* ✅ `values.yaml` with image repository and tag overrides
* ✅ `deployment.yaml` with CPU/memory resource limits
* ✅ `networkpolicy.yaml` to control service communication
* ✅ `ingress.yaml` to expose the frontend

---

### 🔄 Step 3: Connect GitHub to the Cluster with Flux

Install [Flux CLI](https://fluxcd.io/):

```bash
brew install flux
```

Then run:

```bash
export GITHUB_TOKEN=your-token-here
flux bootstrap github \
  --owner=your-github-username \
  --repository=your-repository-name \
  --branch=main \
  --path=clusters/prod \
  --url=https://github.com/your-github-username/your-repository-name.git \
  --personal \
  --token-auth
```

✅ `--token-auth` tells Flux to use HTTPS and GitHub token authentication
✅ Flux will look for the token in the `GITHUB_TOKEN` environment variable
✅ No need to pass `--token` manually unless preferred

Inside `clusters/prod`, you’ll include:

* `source.yaml` → points to your GitHub repo
* `helmrelease.yaml` → deploys your Helm chart from the repo

Flux will keep everything synced between GitHub and your Kubernetes cluster! 🪄✨

And now in the pipeline:
- If Flux is **already installed**, it is **skipped automatically** to avoid re-running the bootstrap
- The `GITHUB_TOKEN` must be present in your pipeline environment as a secret variable

---

## 🌐 4. How to View Your Toy Shop App in Azure

Once everything is deployed to AKS, you’ll want to see the app like a real website!

### 🧠 Step 1: Are You Running on Azure?
If you used the Azure pipeline and see resources in the [Azure Portal](https://portal.azure.com), then ✅ you are in the **cloud**.

### 🔍 Step 2: Find Your App in Azure
1. Go to the **toyshop-aks** resource in the Azure Portal
2. Click on **Kubernetes resources** → **Services and Ingresses**
3. Look for your service like `store-front`

### 🥇 Option A: External IP (Easiest)
If your service type is `LoadBalancer` and shows something like:

```
store-front   LoadBalancer   ...   20.42.88.13
```

Open your browser and go to:

```
http://20.42.88.13
```

🎉 Your Toy Shop app should appear!

### 🥈 Option B: You See "pending" (No IP Yet)
That means there’s no door to the internet yet. We can fix that by:

- Adding an **ingress controller** (like NGINX)
- Or updating your Helm chart to expose via `LoadBalancer`

Let us know if you want help doing that! 🚪✨

---

## 💪 Resilience Features Built-In

- ✅ Terraform **only creates what doesn't exist**
- ✅ Terraform **imports** RG, ACR, AKS if already created
- ✅ Docker images are **only built/imported if missing**
- ✅ Flux install step is **skipped if already present in cluster**
- ✅ Flux uses `--token-auth` with secure GitHub token to bootstrap in CI
- ✅ Pipeline can be run again and again — no crashes, no duplicates

---

🎉 You're all set. Run the pipeline or use the Makefile and watch your Toy Shop come to life! 🧸
