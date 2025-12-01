#!/usr/bin/env bash
set -euo pipefail

# ================================
# ⚙️ Configuration
# ================================
PROJECT_ID=${PROJECT_ID:-""}
LAB_REGION=${LAB_REGION:-""}
LAB_ZONE=${LAB_ZONE:-""}

# ================================
# 🧭 Pre-flight checks
# ================================
if [[ -z "$PROJECT_ID" || -z "$LAB_REGION" || -z "$LAB_ZONE" ]]; then
  echo "❌ Missing required environment variables."
  echo "Please export them before running this script."
  echo ""
  echo "Example:"
  echo "  export PROJECT_ID=my-gcp-project"
  echo "  export LAB_REGION=us-central1"
  echo "  export LAB_ZONE=us-central1-a"
  exit 1
fi

SERVICE_ACCOUNT="eso-sa"
K8S_NAMESPACE="external-secrets"
K8S_SECRET="gcp-credentials"
K8S_SECRETSTORE="gcp-secret-store"
K8S_EXTERNALSECRET="mysql-credentials"

# ================================
# 🔐 Step 1: GCP setup
# ================================
echo "🔐 Setting up Google Secret Manager and Service Account..."

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$LAB_REGION"
gcloud config set compute/zone "$LAB_ZONE"

# Enable APIs
gcloud services enable secretmanager.googleapis.com --quiet

# Create secrets
echo -n "rootpass" | gcloud secrets create mysql-password \
  --replication-policy="automatic" --data-file=- || echo "ℹ️ Secret mysql-password already exists"

echo -n "rootpass" | gcloud secrets create mysql-root-password \
  --replication-policy="automatic" --data-file=- || echo "ℹ️ Secret mysql-root-password already exists"

echo -n "voteuser" | gcloud secrets create mysql-user \
  --replication-policy="automatic" --data-file=- || echo "ℹ️ Secret mysql-user already exists"

# Create service account if not exists
if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SERVICE_ACCOUNT" --display-name="ESO Service Account"
fi

# Grant secret access
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" --quiet

# Create key file
if [[ -f "key.json" ]]; then
  echo "ℹ️ key.json already exists, skipping key creation"
else
  gcloud iam service-accounts keys create key.json \
    --iam-account="$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"
fi

echo "✅ GCP setup complete."

# ================================
# ☸️ Step 2: Kubernetes setup
# ================================
echo "☸️ Setting up Kubernetes resources..."

kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

if ! helm status external-secrets -n "$K8S_NAMESPACE" >/dev/null 2>&1; then
  helm repo add external-secrets https://charts.external-secrets.io
  helm repo update
  helm install external-secrets external-secrets/external-secrets -n "$K8S_NAMESPACE"
else
  echo "ℹ️ ESO already installed, skipping Helm install."
fi

echo "⏳ Waiting for ESO pods to be ready..."
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=external-secrets -n "$K8S_NAMESPACE" --timeout=180s || true

kubectl delete secret "$K8S_SECRET" --ignore-not-found
kubectl create secret generic "$K8S_SECRET" \
  --from-file=credentials.json=key.json

# ================================
# 🧩 Step 3: SecretStore
# ================================
echo "🧩 Creating SecretStore..."
envsubst < gcp-secret-store.yaml | kubectl apply -f -

# ================================
# 🧱 Step 4: ExternalSecret
# ================================
echo "🧱 Creating ExternalSecret for MySQL credentials..."
kubectl apply -f mysql-credentials.yaml

# ================================
# ✅ Done
# ================================
echo ""
echo "🎉 Setup complete!"
echo "Secrets from Google Secret Manager will now sync into your Kubernetes cluster."
echo ""
echo "To verify, run:"
echo "  kubectl get secret mysql-credentials -o yaml"
echo ""
