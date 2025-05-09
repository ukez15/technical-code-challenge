## 📦 Terraform Infrastructure – `infra/`

This folder contains everything we need to set up the **infrastructure** for our app using [Terraform](https://www.terraform.io/).
Think of this as our cloud-building toolkit. When we run it, we get:

* A **resource group** in Azure
* A **container registry (ACR)** to store Docker images
* A **Kubernetes cluster (AKS)** to run our app

All of this is automated in our Azure DevOps pipeline.

---

## 🔧 Files Breakdown

| File           | What it does                                                      |
| -------------- | ----------------------------------------------------------------- |
| `main.tf`      | Defines the cloud resources (RG, ACR, AKS)                        |
| `variables.tf` | Declares variables Terraform needs (like subscription, client ID) |
| `outputs.tf`   | Prints useful info after deployment (like ACR URL)                |

---

## 🚀 How It Works in CI/CD

When the pipeline runs:

1. **Azure login happens using a service connection**
2. **Terraform is installed and initialized**
3. We check if any of the resources (RG, ACR, AKS) **already exist**

   * If they do, we **import them** into Terraform’s state
4. Terraform then **applies** the infrastructure plan

   * If something doesn't exist, it gets created
   * If it already exists and is imported, Terraform manages it

---

## 🔐 Authentication

Terraform uses a **Service Principal** to log into Azure.
The credentials are stored securely in a DevOps variable group called `terraform-auth`, with:

* `ARM_CLIENT_ID`
* `ARM_CLIENT_SECRET`
* `ARM_SUBSCRIPTION_ID`
* `ARM_TENANT_ID`

These are passed to Terraform as environment variables.

---

## 🛑 Safety Notes

* Terraform will **never destroy** existing resources unless explicitly told to.
* It will **not** delete a resource group that contains other resources unless forced (and we don’t do that).
* All imported resources are handled carefully to avoid duplication or errors.

---

## 🧪 Try It Yourself

To run this in the pipeline:

* Commit any changes to the `infra/` folder
* Trigger a pipeline run in Azure DevOps
* Watch the `TerraformInfra` stage deploy your cloud stack!

---
