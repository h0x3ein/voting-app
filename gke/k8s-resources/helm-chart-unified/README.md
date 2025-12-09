# Unified Voting App Helm Chart

This directory contains the **Unified Helm Chart** for the Voting Application. Unlike the separate charts approach, this bundles all microservices (Vote, Result, Worker) and shared resources into a single manageable unit.

## 1. Architecture

This chart deploys the entire stack:
- **Common**: ConfigMap, Secret, ServiceAccount (Workload Identity).
- **Vote App**: Python frontend + Service + Ingress.
- **Result App**: Node.js frontend + Service + Ingress + Cloud SQL Proxy Sidecar.
- **Worker App**: Java background worker + Cloud SQL Proxy Sidecar.

## 2. Prerequisites

The following environment variables **MUST** be exported before installation. These typically come from your Terraform outputs.

```bash
# 1. GCP Project ID (for Workload Identity)
export PROJECT_ID=$(gcloud config get-value project)

# 2. Redis Host (from Terraform)
export REDIS_HOST=$(cd ../../gke-terraform && terraform output -raw redis_host)

# 3. Cloud SQL Connection Name (from Terraform)
# Format: project:region:instance
export CLOUD_SQL_CONNECTION_NAME=$(cd ../../gke-terraform && terraform output -raw cloud_sql_instance_connection_name)

# 4. Database Password
export DB_PASSWORD="vote@pass123456"

# 5. Domain Name (for Ingress)
# e.g., armin.hs or example.com
export DOMAIN_NAME="armin.hs"
```

## 3. Installation

### Method A: Quick Script (Recommended)
We provide a script that checks variables and installs the chart.
```bash
chmod +x install.sh
./install.sh
```

### Method B: Manual Helm Install
If you prefer to run Helm directly:

```bash
helm upgrade --install voting-app . \
  --set global.projectID=$PROJECT_ID \
  --set global.db.connectionName=$CLOUD_SQL_CONNECTION_NAME \
  --set global.db.password=$DB_PASSWORD \
  --set global.redis.host=$REDIS_HOST \
  --set vote.ingress.host="vote.$DOMAIN_NAME" \
  --set result.ingress.host="result.$DOMAIN_NAME"
```

## 4. Configuration
Key configuration overrides available in `values.yaml`:

| Section | Key | Description |
| :--- | :--- | :--- |
| `global` | `projectID` | GCP Project ID |
| `global` | `db.connectionName` | Cloud SQL Connection String |
| `vote` | `ingress.host` | Domain for Vote App |
| `result` | `ingress.host` | Domain for Result App |
| `worker` | `replicaCount` | Worker replicas |
