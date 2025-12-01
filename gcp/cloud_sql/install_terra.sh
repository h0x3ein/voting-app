#!/bin/bash

# Fail the script on errors, unset variables, and pipefail
set -euo pipefail

# ==============================
# 🔧 Configuration Variables
# ==============================

# Assign environment variables, defaulting to empty strings if not set
export PROJECT_ID="${PROJECT_ID:-}"
export LAB_REGION="${LAB_REGION:-}"
export DB_INSTANCE_NAME="${DB_INSTANCE_NAME:-}"

# ==============================
# 🧭 Pre-flight Checks: Ensure Variables are Set
# ==============================

# Check if the required environment variables are set
if [[ -z "$PROJECT_ID" || -z "$LAB_REGION" || -z "$DB_INSTANCE_NAME" ]]; then
  echo "❌ Missing required environment variables."
  echo "Please ensure the following environment variables are set:"
  echo "  - PROJECT_ID"
  echo "  - LAB_REGION"
  echo "  - DB_INSTANCE_NAME"
  echo ""
  echo "Example usage:"
  echo "  export PROJECT_ID=my-project"
  echo "  export LAB_REGION=us-central1"
  echo "  export DB_INSTANCE_NAME=my-db-instance"
  exit 1
fi

# ==============================
# Set other necessary variables
# ==============================

export K8S_NAMESPACE="vote-app"
export PROXY_SA_NAME="cloudsql-proxy"
export PROXY_KEY_FILE="./cloudsql-proxy-key.json"
export PROXY_SECRET_NAME="cloudsql-sa-key"
export PROXY_DEPLOYMENT_NAME="cloudsql-proxy"
export PROXY_YAML_PATH="./cloudsql-proxy.yaml"

# Continue with the rest of the script...
# Fetch the Cloud SQL Proxy key from Terraform output and decode it to the key.json file
(cd ../latest_terraform && terraform output -raw cloudsql_proxy_key) | base64 --decode > ./cloudsql-proxy-key.json

# ==============================
# 🚀 Update Kubernetes Secret with the new key
# ==============================
echo "📦 Updating Kubernetes secret for proxy key..."

# Delete the existing secret if it exists
kubectl get secret "$PROXY_SECRET_NAME" -n "$K8S_NAMESPACE" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ℹ️ Secret '$PROXY_SECRET_NAME' exists. Deleting it..."
  kubectl delete secret "$PROXY_SECRET_NAME" -n "$K8S_NAMESPACE"
fi

# Create a new Kubernetes secret with the updated key
kubectl -n "$K8S_NAMESPACE" create secret generic "$PROXY_SECRET_NAME" \
  --from-file=key.json="$PROXY_KEY_FILE"
echo "✅ Created/Updated Kubernetes secret '$PROXY_SECRET_NAME' for proxy key."

# ==============================
# 🚀 Deploy Cloud SQL Proxy
# ==============================
if [ ! -f "$PROXY_YAML_PATH" ]; then
  echo "❌ Missing $PROXY_YAML_PATH"
  echo "Please ensure cloudsql-proxy.yaml exists at this path."
  exit 1
fi

echo "🚀 Applying Cloud SQL Proxy deployment..."
# Apply the Cloud SQL Proxy deployment using envsubst to substitute environment variables in the YAML
envsubst < "$PROXY_YAML_PATH" | kubectl apply -n "$K8S_NAMESPACE" -f -

# ==============================
# ✅ Done
# ==============================
echo ""
echo "🎉 Installation complete!"
echo "-------------------------------------------------------------"
echo "✅ Cloud SQL Instance: $DB_INSTANCE_NAME"
#echo "✅ Connection name: $INSTANCE_CONNECTION_NAME"
echo "✅ Kubernetes Secret: $PROXY_SECRET_NAME (new key.json)"
echo "✅ Namespace: $K8S_NAMESPACE"
echo "✅ Proxy Deployment: $PROXY_DEPLOYMENT_NAME"
echo ""
echo "To verify proxy connection:"
echo "  kubectl logs -n $K8S_NAMESPACE deploy/$PROXY_DEPLOYMENT_NAME"
echo ""
echo "To test MySQL connection inside cluster:"
echo "  kubectl run sql-client --rm -it --image=mysql:8 --namespace=$K8S_NAMESPACE -- bash"
echo "  mysql -h mysql-proxy -P 3306 -uDB_USER -pDB_PASS DB_NAME -e 'SELECT VERSION();'"
echo "-------------------------------------------------------------"
