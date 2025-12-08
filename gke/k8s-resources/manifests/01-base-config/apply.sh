#!/bin/bash
set -e

# Script to apply Kubernetes base configuration with environment variable substitution
# Usage: 
#   export PROJECT_ID=$(gcloud config get-value project)
#   export REDIS_HOST=$(cd ../../gke-terraform && terraform output -raw redis_host)
#   export CLOUD_SQL_CONNECTION_NAME=$(cd ../../gke-terraform && terraform output -raw cloud_sql_instance_connection_name)
#   export DB_PASSWORD="vote@pass123456"
#   ./apply.sh

echo "🔍 Checking required environment variables..."

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: PROJECT_ID environment variable is not set"
  echo "Run: export PROJECT_ID=\$(gcloud config get-value project)"
  exit 1
fi

if [ -z "$REDIS_HOST" ]; then
  echo "❌ Error: REDIS_HOST environment variable is not set"
  echo "Run: export REDIS_HOST=\$(cd ../../gke-terraform && terraform output -raw redis_host)"
  exit 1
fi

if [ -z "$CLOUD_SQL_CONNECTION_NAME" ]; then
  echo "❌ Error: CLOUD_SQL_CONNECTION_NAME environment variable is not set"
  echo "Run: export CLOUD_SQL_CONNECTION_NAME=\$(cd ../../gke-terraform && terraform output -raw cloud_sql_instance_connection_name)"
  exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "❌ Error: DB_PASSWORD environment variable is not set"
  echo "Run: export DB_PASSWORD=\"your-password-from-terraform.tfvars\""
  exit 1
fi

echo "✅ All environment variables are set:"
echo "   PROJECT_ID: $PROJECT_ID"
echo "   REDIS_HOST: $REDIS_HOST"
echo "   CLOUD_SQL_CONNECTION_NAME: $CLOUD_SQL_CONNECTION_NAME"
echo "   DB_PASSWORD: ****"

echo ""
echo "📦 Applying base configuration..."

# Apply with environment variable substitution
envsubst < serviceaccounts.yaml | kubectl apply -f -
envsubst < configmap-voteapp.yaml | kubectl apply -f -
envsubst < secret-voteapp.yaml | kubectl apply -f -

echo ""
echo "✅ Base configuration applied successfully!"
echo ""
echo "Verify with:"
echo "  kubectl get sa,configmap,secret -n vote-app"
