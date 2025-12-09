#!/bin/bash
set -e

echo "🔹 Checking Environment Variables..."

# 1. Project ID
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: PROJECT_ID is not set."
  echo "Run: export PROJECT_ID=\$(gcloud config get-value project)"
  exit 1
fi

# 2. Redis Host
if [ -z "$REDIS_HOST" ]; then
  echo "❌ Error: REDIS_HOST is not set."
  echo "Run: export REDIS_HOST=..."
  exit 1
fi

# 3. Cloud SQL Connection Name
if [ -z "$CLOUD_SQL_CONNECTION_NAME" ]; then
  echo "❌ Error: CLOUD_SQL_CONNECTION_NAME is not set."
  echo "Run: export CLOUD_SQL_CONNECTION_NAME=..."
  exit 1
fi

# 4. DB Password (Default if missing)
if [ -z "$DB_PASSWORD" ]; then
  echo "⚠️  Warning: DB_PASSWORD is not set. Using default 'vote@pass123456'"
  export DB_PASSWORD="vote@pass123456"
fi

# 5. Domain Name (Default if missing)
if [ -z "$DOMAIN_NAME" ]; then
  echo "⚠️  Warning: DOMAIN_NAME is not set. Using default 'armin.hs'"
  export DOMAIN_NAME="armin.hs"
fi

echo "✅ Variables Verified:"
echo "  - Project:   $PROJECT_ID"
echo "  - Redis:     $REDIS_HOST"
echo "  - Cloud SQL: $CLOUD_SQL_CONNECTION_NAME"
echo "  - Password:  [HIDDEN]"
echo "  - Domain:    $DOMAIN_NAME"

echo ""
echo "----------------------------------------------------"
echo "🚀 Step 1: Installing Common Chart (Shared Config)"
echo "----------------------------------------------------"
# We inject the Cloud SQL and Redis configs here. 
# The Common chart puts them into a ConfigMap.
helm upgrade --install common ./common \
  --set global.projectID=$PROJECT_ID \
  --set db.password=$DB_PASSWORD \
  --set db.connectionName=$CLOUD_SQL_CONNECTION_NAME \
  --set redis.host=$REDIS_HOST

echo ""
echo "----------------------------------------------------"
echo "🚀 Step 2: Installing Vote App (Frontend)"
echo "----------------------------------------------------"
# Vote App reads DB/Redis config from Common's ConfigMap.
# We only need to set the Ingress Host.
helm upgrade --install vote ./vote \
  --set ingress.host="vote.$DOMAIN_NAME"

echo ""
echo "----------------------------------------------------"
echo "🚀 Step 3: Installing Result App (Results View)"
echo "----------------------------------------------------"
# Result App reads DB config from Common's ConfigMap.
# We only need to set the Ingress Host.
helm upgrade --install result ./result \
  --set ingress.host="result.$DOMAIN_NAME"

echo ""
echo "----------------------------------------------------"
echo "🚀 Step 4: Installing Worker App (Background)"
echo "----------------------------------------------------"
# Worker App reads everything from Common's ConfigMap.
# No overrides needed.
helm upgrade --install worker ./worker

echo ""
echo "🎉 All charts installed successfully!"
