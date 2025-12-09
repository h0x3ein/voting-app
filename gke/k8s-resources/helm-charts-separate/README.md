# Voting App Helm Charts

This directory contains the Helm charts for the partial microservices of the Voting App using a Micro-Chart architecture.

## 1. Architecture Overview

- **`common`**: Creates the shared **ConfigMap** (`voteapp-config`) and **Secret** (`voteapp-secret`). All other charts depend on this.
- **`vote`** (Python): Frontend app. Reads DB/Redis config from `voteapp-config`.
- **`result`** (Node.js): Frontend/Backend app. Reads DB config from `voteapp-config`.
- **`worker`** (Java): Backend worker. Reads DB/Redis config from `voteapp-config`.

## 2. Prerequisites (Initialize Variables)

Before installing, you must set the following environment variables. These values are injected into the `common` chart and then shared with the apps.

```bash
# 1. GCP Project ID (Required for Workload Identity)
export PROJECT_ID=$(gcloud config get-value project)

# 2. Redis Host (From Terraform Output)
# Replace with your actual Redis IP or use terraform output
export REDIS_HOST=$(cd /../../gke-terraform && terraform output -raw redis_host)

# 3. Cloud SQL Connection Name (From Terraform Output)
# Format: project:region:instance
export CLOUD_SQL_CONNECTION_NAME=$(cd ../../gke-terraform && terraform output -raw cloud_sql_instance_connection_name)

# 4. Database Password
# Ensure this matches what you set in Terraform/Cloud SQL
export DB_PASSWORD="vote@pass123456"

# 5. Domain Name
# The base domain for ingress (e.g., armin.hs or example.com)
export DOMAIN_NAME="armin.hs"
```

## 3. Installation

You can install the charts manually or use the provided script.

### Option A: Quick Install Script (Recommended)
This script checks for the variables above and installs all charts in the correct order.

```bash
chmod +x install.sh
./install.sh
```

### Option B: Manual Installation

**Step 1: Install Common Chart**
*This initializes the shared configuration.*
```bash
helm upgrade --install common ./common \
  --set global.projectID=$PROJECT_ID \
  --set db.password=$DB_PASSWORD \
  --set db.connectionName=$CLOUD_SQL_CONNECTION_NAME \
  --set redis.host=$REDIS_HOST
```

**Step 2: Install Vote App**
```bash
helm upgrade --install vote ./vote \
  --set ingress.host="vote.$DOMAIN_NAME"
```

**Step 3: Install Result App**
```bash
helm upgrade --install result ./result \
  --set ingress.hosts.host="result.$DOMAIN_NAME"
```

**Step 4: Install Worker App**
```bash
helm upgrade --install worker ./worker
```

## 4. Configuration Reference

| Chart | Parameter | Description | Source |
|-------|-----------|-------------|--------|
| **common** | `db.connectionName` | Cloud SQL Connection string | Initialized from `$CLOUD_SQL_CONNECTION_NAME` |
| **common** | `redis.host` | Redis IP address | Initialized from `$REDIS_HOST` |
| **vote** | `ingress.host` | URL for Vote App | Initialized from `$DOMAIN_NAME` |
| **result** | `ingress.hosts` | URL for Result App | Initialized from `$DOMAIN_NAME` |

> **Note:** You do NOT need to set `connectionName` in `result` or `worker` values. They automatically read it from the `voteapp-config` ConfigMap created by the `common` chart.
