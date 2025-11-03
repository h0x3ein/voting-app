#!/usr/bin/env bash
set -euo pipefail

##########################################
# 🧹 0. Cleanup Old Kubernetes Resources
##########################################
echo "🧹 Cleaning up existing External Secrets resources..."

K8S_NAMESPACE="vote-app"
K8S_SECRET="gcp-credentials"
K8S_SECRETSTORE="gcp-secret-store"
K8S_EXTERNALSECRET="voteapp-secret"

kubectl delete externalsecret "$K8S_EXTERNALSECRET" -n "$K8S_NAMESPACE" --ignore-not-found
kubectl delete secretstore "$K8S_SECRETSTORE" -n "$K8S_NAMESPACE" --ignore-not-found
kubectl delete secret "$K8S_SECRET" -n "$K8S_NAMESPACE" --ignore-not-found

echo "✅ Old resources removed."


##########################################
# 🔑 2. Extract Service Account Key from Terraform
##########################################
echo "🔑 Exporting ESO service account key from Terraform..."

# Go into Terraform directory to read output, store key locally in secretmanager/
(cd ../terraform && terraform output -raw eso_private_key) | base64 --decode > ./key.json

if [[ ! -s ./key.json ]]; then
  echo "❌ Failed to extract key from Terraform output. Exiting."
  exit 1
fi

##########################################
# 🗝️ 3. Create Kubernetes Secret with GCP Credentials
##########################################
echo "🗝️ Creating Kubernetes secret for GCP credentials..."
kubectl -n "$K8S_NAMESPACE" create secret generic gcp-credentials \
  --from-file=credentials.json=./key.json \
  --dry-run=client -o yaml | kubectl apply -f -

##########################################
# ☁️ 4. Apply SecretStore (connects K8s → GCP Secret Manager)
##########################################
echo "☁️ Applying SecretStore configuration..."
export PROJECT_ID="qwiklabs-gcp-04-8ddc9823819a"
envsubst < gcp-secret-store.yaml | kubectl -n "$K8S_NAMESPACE" apply -f -

##########################################
# 🔐 5. Apply ExternalSecret (syncs real secrets)
##########################################
echo "🔐 Applying ExternalSecret configuration..."
kubectl -n "$K8S_NAMESPACE" apply -f mysql-credentials.yaml

##########################################
# ✅ 6. Verify
##########################################
echo ""
echo "✅ Installation complete!"
echo "🔎 Checking resources..."
kubectl -n "$K8S_NAMESPACE" get secretstores,externalsecrets,secrets

