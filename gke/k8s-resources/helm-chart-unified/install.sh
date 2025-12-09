#!/bin/bash
set -e

echo "🔹 Unified Chart: Checking Environment Variables..."

# 1. Project ID
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: PROJECT_ID is not set."
  exit 1
fi

# 2. Redis Host
if [ -z "$REDIS_HOST" ]; then
  echo "❌ Error: REDIS_HOST is not set."
  echo "Tip: export REDIS_HOST=\$(cd ../../gke-terraform && terraform output -raw redis_host)"
  exit 1
fi

# 3. Cloud SQL Connection Name
if [ -z "$CLOUD_SQL_CONNECTION_NAME" ]; then
  echo "❌ Error: CLOUD_SQL_CONNECTION_NAME is not set."
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

echo "✅ Variables Verified."
echo "   Domain: $DOMAIN_NAME"
echo ""

echo "🚀 Installing Unified Voting App..."
helm upgrade --install voting-app . \
  --set global.projectID=$PROJECT_ID \
  --set global.db.connectionName=$CLOUD_SQL_CONNECTION_NAME \
  --set global.db.password=$DB_PASSWORD \
  --set global.redis.host=$REDIS_HOST \
  --set vote.ingress.host="vote.$DOMAIN_NAME" \
  --set result.ingress.host="result.$DOMAIN_NAME"

echo ""
echo "🎉 Deployment Complete!"
