#!/usr/bin/env bash
#
# ---------------------------------------------------------
# Cloud SQL (MySQL) + Cloud SQL Auth Proxy setup for Voting App
# Clean + Safe Installation Script
# ---------------------------------------------------------
# Author: Ho3ein 🧑‍💻
# Purpose:
#   Ensures a clean environment before creating a new
#   Cloud SQL instance, Service Account, and Proxy in Kubernetes.
# ---------------------------------------------------------

set -euo pipefail

# ==============================
# 🔧 Configuration Variables
# ==============================
export PROJECT_ID="${PROJECT_ID:-}"
export LAB_REGION="${LAB_REGION:-}"
export LAB_ZONE="${LAB_ZONE:-}"
export DB_INSTANCE_NAME="${DB_INSTANCE_NAME:-}"
export DB_NAME="${DB_NAME:-}"
export DB_USER="${DB_USER:-}"
export DB_PASS="${DB_PASS:-}"
export DB_ROOT_PASS="${DB_ROOT_PASS:-}"
export K8S_NAMESPACE="vote-app"
export PROXY_SA_NAME="cloudsql-proxy"
export PROXY_KEY_FILE="./cloudsql-proxy-key.json"
export PROXY_SECRET_NAME="cloudsql-sa-key"
export PROXY_DEPLOYMENT_NAME="cloudsql-proxy"
export PROXY_YAML_PATH="./cloudsql-proxy.yaml"

# ==============================
# 🧩 Validation
# ==============================
echo "🔍 Validating environment variables..."
missing_vars=()

for var in PROJECT_ID LAB_REGION LAB_ZONE DB_INSTANCE_NAME DB_NAME DB_USER DB_PASS DB_ROOT_PASS; do
  if [ -z "${!var:-}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  echo "❌ Missing required variables: ${missing_vars[*]}"
  echo "Please export them before running this script."
  exit 1
fi

echo "✅ Environment looks good."

# ==============================
# 🧹 Cleanup Phase
# ==============================
echo "🧹 Cleaning up old Cloud SQL proxy artifacts..."

# 1️⃣ Remove old local key file
if [ -f "$PROXY_KEY_FILE" ]; then
  echo "🗑️ Removing old local key file: $PROXY_KEY_FILE"
  rm -f "$PROXY_KEY_FILE"
fi

# 2️⃣ Remove old Kubernetes resources (only proxy-related)
if kubectl get ns "$K8S_NAMESPACE" >/dev/null 2>&1; then
  echo "🧼 Cleaning proxy resources in namespace: $K8S_NAMESPACE"
  kubectl -n "$K8S_NAMESPACE" delete deploy "$PROXY_DEPLOYMENT_NAME" --ignore-not-found
  kubectl -n "$K8S_NAMESPACE" delete svc mysql-proxy --ignore-not-found
  kubectl -n "$K8S_NAMESPACE" delete secret "$PROXY_SECRET_NAME" --ignore-not-found
  kubectl -n "$K8S_NAMESPACE" delete sa "$PROXY_SA_NAME" --ignore-not-found
  kubectl -n "$K8S_NAMESPACE" delete configmap cloudsql-proxy-config --ignore-not-found
else
  echo "ℹ️ Namespace $K8S_NAMESPACE not found, skipping K8s cleanup."
fi

echo "✅ Cleanup complete. Starting fresh installation..."
sleep 2

# ==============================
# ⚙️ GCP Setup
# ==============================
echo "🚀 Setting GCP project and enabling required APIs..."
gcloud config set project "$PROJECT_ID"
gcloud services enable sqladmin.googleapis.com iam.googleapis.com

# ==============================
# 🗃️ Create Cloud SQL Instance
# ==============================
echo "📦 Creating Cloud SQL MySQL instance: $DB_INSTANCE_NAME ..."
if ! gcloud sql instances describe "$DB_INSTANCE_NAME" >/dev/null 2>&1; then
  gcloud sql instances create "$DB_INSTANCE_NAME" \
    --database-version=MYSQL_8_0 \
    --tier=db-custom-1-3840 \
    --region="$LAB_REGION" \
    --root-password="$DB_ROOT_PASS"
else
  echo "ℹ️ Cloud SQL instance $DB_INSTANCE_NAME already exists. Skipping creation."
fi

echo "📚 Creating database and user..."
gcloud sql databases create "$DB_NAME" --instance="$DB_INSTANCE_NAME" || echo "ℹ️ Database may already exist."
gcloud sql users create "$DB_USER" --instance="$DB_INSTANCE_NAME" --password="$DB_PASS" || echo "ℹ️ User may already exist."

export INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe "$DB_INSTANCE_NAME" --format="value(connectionName)")
echo "✅ INSTANCE_CONNECTION_NAME=$INSTANCE_CONNECTION_NAME"

# ==============================
# 🔐 Service Account Setup
# ==============================
echo "🔐 Creating service account: $PROXY_SA_NAME ..."
gcloud iam service-accounts create "$PROXY_SA_NAME" --display-name="Cloud SQL Proxy for Vote App" || echo "ℹ️ SA may already exist."

export PROXY_SA_EMAIL="$PROXY_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo "👑 Assigning Cloud SQL Client role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$PROXY_SA_EMAIL" \
  --role="roles/cloudsql.client" >/dev/null

echo "🔑 Generating fresh key: $PROXY_KEY_FILE"
gcloud iam service-accounts keys create "$PROXY_KEY_FILE" --iam-account="$PROXY_SA_EMAIL"

# ==============================
# ☸️ Kubernetes Integration
# ==============================
echo "☸️ Ensuring namespace $K8S_NAMESPACE exists..."
kubectl get ns "$K8S_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$K8S_NAMESPACE"

echo "📦 Creating fresh Kubernetes secret for proxy key..."
kubectl -n "$K8S_NAMESPACE" create secret generic "$PROXY_SECRET_NAME" \
  --from-file=key.json="$PROXY_KEY_FILE"

# ==============================
# 🚀 Deploy Cloud SQL Proxy
# ==============================
if [ ! -f "$PROXY_YAML_PATH" ]; then
  echo "❌ Missing $PROXY_YAML_PATH"
  echo "Please ensure cloudsql-proxy.yaml exists at this path."
  exit 1
fi

echo "🚀 Applying Cloud SQL Proxy deployment..."
#kubectl apply -f "$PROXY_YAML_PATH" -n "$K8S_NAMESPACE"
envsubst < "$PROXY_YAML_PATH" | kubectl apply -n "$K8S_NAMESPACE" -f -

# ==============================
# ✅ Done
# ==============================
echo ""
echo "🎉 Installation complete!"
echo "-------------------------------------------------------------"
echo "✅ Cloud SQL Instance: $DB_INSTANCE_NAME"
echo "✅ Connection name: $INSTANCE_CONNECTION_NAME"
echo "✅ Kubernetes Secret: $PROXY_SECRET_NAME (new key.json)"
echo "✅ Namespace: $K8S_NAMESPACE"
echo "✅ Proxy Deployment: $PROXY_DEPLOYMENT_NAME"
echo ""
echo "To verify proxy connection:"
echo "  kubectl logs -n $K8S_NAMESPACE deploy/$PROXY_DEPLOYMENT_NAME"
echo ""
echo "To test MySQL connection inside cluster:"
echo "  kubectl run sql-client --rm -it --image=mysql:8 --namespace=$K8S_NAMESPACE -- bash"
echo "  mysql -h mysql-proxy -P 3306 -u$DB_USER -p$DB_PASS $DB_NAME -e 'SELECT VERSION();'"
echo "-------------------------------------------------------------"
