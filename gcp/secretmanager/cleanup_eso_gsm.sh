#!/usr/bin/env bash
set -euo pipefail

# ================================
# 🧩 Configuration
# ================================
PROJECT_ID=${PROJECT_ID:-""}

if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ PROJECT_ID is not set. Please export PROJECT_ID before running this script."
  echo "Example: export PROJECT_ID=my-gcp-project"
  exit 1
fi

SERVICE_ACCOUNT="eso-sa"

# GCP Secret names
SECRETS=(
  "mysql-password"
  "mysql-root-password"
  "mysql-user"
)

# Kubernetes resources
K8S_NAMESPACE="external-secrets"
K8S_SECRET="gcp-credentials"
K8S_SECRETSTORE="gcp-secret-store"
K8S_EXTERNALSECRET="mysql-credentials"

# ================================
# ☸️  Kubernetes Cleanup
# ================================

echo "🧹 Cleaning up Kubernetes resources..."

kubectl delete externalsecret "$K8S_EXTERNALSECRET" --ignore-not-found
kubectl delete secretstore "$K8S_SECRETSTORE" --ignore-not-found
kubectl delete secret "$K8S_SECRET" --ignore-not-found

echo "✅ Kubernetes cleanup complete."

# ================================
# 🌩️  GCP Cleanup
# ================================

echo "🧹 Cleaning up GCP resources..."

for SECRET_NAME in "${SECRETS[@]}"; do
  if gcloud secrets describe "$SECRET_NAME" --project "$PROJECT_ID" >/dev/null 2>&1; then
    gcloud secrets delete "$SECRET_NAME" --project "$PROJECT_ID" --quiet
    echo "🗑️  Deleted secret: $SECRET_NAME"
  else
    echo "ℹ️  Secret $SECRET_NAME not found in project $PROJECT_ID"
  fi
done

# Delete the service account
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts delete "$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" --quiet
  echo "🗑️  Deleted service account: $SERVICE_ACCOUNT"
else
  echo "ℹ️  Service account $SERVICE_ACCOUNT not found."
fi

# Delete the local key file if it exists
if [[ -f "key.json" ]]; then
  rm -f key.json
  echo "🧾 Deleted local key.json file"
fi

echo "✅ GCP cleanup complete."

# ================================
# 🧼 Done
# ================================

echo "🎉 All resources from ESO + GSM lab have been cleaned up successfully!"
