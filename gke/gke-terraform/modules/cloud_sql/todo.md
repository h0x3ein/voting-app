# Cloud SQL Implementation Checklist

This checklist tracks the steps required to provision a Cloud SQL (PostgreSQL) instance and connect it to the GKE cluster using Private Service Access.

## 1. Enable Required APIs (Project Module)
- [ ] Ensure `sqladmin.googleapis.com` is enabled in your project module (or manually).
- [ ] Ensure `servicenetworking.googleapis.com` is enabled (likely done for Redis).

## 2. Network Configuration (Network Module)
*Note: This is shared infrastructure with Redis. It is likely already completed.*
- [ ] Verify **Allocated IP Range** exists for `servicenetworking`.
- [ ] Verify **Private Connection** (VPC Peering) exists between your VPC and Google Services.

## 3. Terraform: Cloud SQL Module
- [ ] Create `modules/cloud_sql/variables.tf`.
- [ ] Create `modules/cloud_sql/main.tf` with the following resources:
    - `google_sql_database_instance`:
        - Set `settings.ip_configuration.private_network` to your VPC ID.
        - Set `deletion_protection = false` (for learning/labs).
    - `google_sql_user`: Create a default user (e.g., `voting-app-user`).
    - `google_sql_database`: Create a default database (e.g., `voting-app-db`).
- [ ] Create `modules/cloud_sql/outputs.tf`:
    - Output `instance_connection_name` (Important for Auth Proxy).
    - Output `private_ip_address`.

## 4. Kubernetes: Workload Identity (IAM)
*Securely allow GKE pods to authenticate with Cloud SQL.*
- [ ] Create a Google Service Account (GSA) for Cloud SQL Client (e.g., `cloud-sql-sa`).
- [ ] Grant `roles/cloudsql.client` to this GSA.
- [ ] Bind this GSA to a Kubernetes Service Account (KSA) using Workload Identity (`roles/iam.workloadIdentityUser`).
- [ ] Create the KSA in the `voting-app` namespace (or default).

## 5. Deployment Updates (Manifests/Helm)
- [ ] Update your application Deployment (e.g., `worker` or `result` app) to include the **Cloud SQL Auth Proxy** sidecar container.
- [ ] Configure the app to connect to `localhost:5432` (traffic goes through the sidecar).
- [ ] Pass database credentials via Kubernetes Secrets.

## 6. Verification
- [ ] Apply Terraform changes.
- [ ] Deploy a test pod with `pg_isready` (see `cloud_sql.md`).
- [ ] Verify connection from the application.
