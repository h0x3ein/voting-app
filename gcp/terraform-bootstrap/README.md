# 🏗️ Terraform Bootstrap — Remote Backend on GCS

This Terraform configuration **bootstraps a Google Cloud Storage (GCS) bucket** used to store remote Terraform state for other environments or projects.

It’s designed for **temporary lab or project setups** (e.g., Qwiklabs, GCP training environments), but follows **production-grade structure** for clarity and reuse.

---

## 📦 What This Project Does

This repository:

- Creates a **Google Cloud Storage bucket** to hold Terraform state.
- Enables **versioning** on the bucket for rollback protection.
- Outputs the **bucket name** and **URL** for use in other Terraform projects.

Example output:
```bash
Outputs:

tf_bucket_name = "my-lab-tfstate-qwiklabs-gcp-00-d497181e326b"
````

---

## 📁 Project Structure

```
terraform-bootstrap/
├── main.tf             # Defines the GCS bucket resource
├── provider.tf         # Configures the Google provider
├── variables.tf        # Declares project_id and region variables
├── terraform.tfvars    # Provides values for variables (project_id, region)
├── outputs.tf          # Exposes bucket name and URL for reuse
├── .terraform/         # Provider binaries (auto-managed)
├── .terraform.lock.hcl # Provider version lock file
├── terraform.tfstate   # Local state file (created after apply)
└── README.md           # Documentation (this file)
```

---

## ⚙️ How It Works

### 1. Create a Remote Backend Bucket

Terraform provisions a versioned GCS bucket:

```hcl
resource "google_storage_bucket" "tf_bucket" {
  name     = "my-lab-tfstate-${var.project_id}"
  location = var.region

  versioning {
    enabled = true
  }
}
```

This ensures that:

* Every project gets its own unique backend bucket (`my-lab-tfstate-<project_id>`).
* All Terraform state changes are versioned (rollback possible).
* The bucket is regionally replicated for reliability.

---

## 🧩 Input Variables

| Variable     | Description                                 | Example                          |
| ------------ | ------------------------------------------- | -------------------------------- |
| `project_id` | GCP Project ID                              | `"qwiklabs-gcp-00-d497181e326b"` |
| `region`     | GCP region where the bucket will be created | `"us-west1"`                     |

Defined in [`variables.tf`](./variables.tf).

Values are passed via [`terraform.tfvars`](./terraform.tfvars):

```hcl
project_id = "qwiklabs-gcp-00-d497181e326b"
region     = "us-west1"
```

---

## 📤 Outputs

| Output           | Description                    | Example                                            |
| ---------------- | ------------------------------ | -------------------------------------------------- |
| `tf_bucket_name` | Name of the created GCS bucket | `my-lab-tfstate-qwiklabs-gcp-00-d497181e326b`      |

---

## 🚀 Usage

### 1️⃣ Initialize Terraform

```bash
terraform init
```

### 2️⃣ Review the plan

```bash
terraform plan
```

### 3️⃣ Apply to create the bucket

```bash
terraform apply -auto-approve
```

### 4️⃣ Verify Outputs

```bash
terraform output
```

You’ll see your new state bucket name and URL.

---

## 🪣 Example: Using This Bucket as a Remote Backend

In your **main Terraform project**, reference the bucket you created:

```hcl
terraform {
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-00-d497181e326b"
    prefix = "terraform/state"
  }
}
```

Then reinitialize:

```bash
terraform init -migrate-state
```

Now your Terraform state is stored securely and remotely in GCS.

---

## 🔐 Security Notes

* **Versioning** ensures state rollback is possible after failed deploys.
* **No public access** — the bucket uses default IAM and is private to the project.
* For production, enable:

  * `uniform_bucket_level_access = true`
  * `force_destroy = false`
  * `encryption` (CMEK or default Google-managed keys)

---

## 🧠 Why Separate This Bootstrap Project?

In real-world SRE / DevOps setups:

* The **Terraform backend** (remote state bucket, IAM bootstrap) is managed **before** all other resources.
* It provides a stable foundation for multi-team, multi-environment Terraform setups.
* Separation improves **reproducibility** and **least privilege** — other Terraform modules only read/write state; they don’t create buckets.

---

## 🧹 Clean Up (for Labs)

Since Qwiklabs environments are temporary:

```bash
terraform destroy -auto-approve
```

This will remove the bucket and clean up state resources.

---

## 📚 References

* [Terraform GCS Backend Docs](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
* [Google Cloud Storage Documentation](https://cloud.google.com/storage/docs)
* [Best Practices for Managing Terraform State](https://developer.hashicorp.com/terraform/language/state/purpose)

---

## 🧩 Author Notes

* Built for GCP Qwiklabs / Sandbox projects.
* Compatible with Terraform **v1.13+** and Google Provider **v7.9+**.
* Simple enough for labs — structured enough for production.


