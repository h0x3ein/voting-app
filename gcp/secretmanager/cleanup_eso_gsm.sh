#!/usr/bin/env bash
set -euo pipefail

# ================================
# 🧩 Configuration
# ================================
PROJECT_ID=${PROJECT_ID:-""}

#if [[ -z "$PROJECT_ID" ]]; then
#  echo "❌ PROJECT_ID is not set. Please export PROJECT_ID before running this script."
#  echo "Example: export PROJECT_ID=my-gcp-project"
#  exit 1
#fi



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
