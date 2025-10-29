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
  echo "  export LAB_REGION=us-east1"
  echo "  export LAB_ZONE=us-east1-b"
  exit 1
fi

REGION="$LAB_REGION"
ZONE="$LAB_ZONE"
NETWORK="default"
REDIS_INSTANCE="my-redis"
PROXY_VM="redis-proxy"
ROUTER_NAME="default-router"
NAT_NAME="default-nat"
MACHINE_TYPE="e2-micro"
FW_RULE_NAME="allow-redis-proxy-6379"

# ================================
# 🔍 0. Check region & zone
# ================================
echo "🔍 Checking available zones in $REGION..."
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# ================================
# 🔧 1. Enable required APIs
# ================================
echo "🔧 Enabling required APIs..."
gcloud services enable \
  compute.googleapis.com \
  redis.googleapis.com \
  servicenetworking.googleapis.com \
  vpcaccess.googleapis.com --quiet

# ================================
# 🧱 2. Create Redis (private)
# ================================

# ================================
# 🔌 Setup Private Service Access
# ================================
echo "🔌 Setting up Private Service Access for $NETWORK..."

# 1. Reserve an internal IP range (only once per project/network)
gcloud compute addresses create google-managed-services-range \
  --global \
  --purpose=VPC_PEERING \
  --addresses=10.0.0.0 \
  --prefix-length=24 \
  --network="$NETWORK" \
  --project="$PROJECT_ID" || echo "ℹ️ Address range may already exist."

# 2. Create the VPC connection for PSA
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services-range \
  --network="$NETWORK" \
  --project="$PROJECT_ID" \
  --quiet || echo "ℹ️ Private service access may already be configured."

echo "✅ Private Service Access configured."


echo "🧱 Creating Redis instance..."
gcloud redis instances create "$REDIS_INSTANCE" \
  --size=1 \
  --region="$REGION" \
  --tier=STANDARD \
  --network="$NETWORK" \
  --connect-mode=PRIVATE_SERVICE_ACCESS || echo "ℹ️ Redis instance may already exist."

echo "⏳ Waiting for Redis to be ready..."
gcloud redis instances describe "$REDIS_INSTANCE" --region="$REGION" --format="get(host)" || true

# ================================
# 🖥️ 3. Create Proxy VM (no public IP)
# ================================
echo "🖥️ Creating proxy VM (no public IP)..."
gcloud compute instances create "$PROXY_VM" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --subnet="$NETWORK" \
  --no-address || echo "ℹ️ Proxy VM may already exist."

# ================================
# 🌐 4. Setup Cloud Router & NAT
# ================================
echo "🌐 Setting up Cloud Router + NAT..."
gcloud compute routers create "$ROUTER_NAME" \
  --network="$NETWORK" \
  --region="$REGION" \
  --quiet || echo "ℹ️ Router may already exist."

gcloud compute routers nats create "$NAT_NAME" \
  --router="$ROUTER_NAME" \
  --region="$REGION" \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges \
  --quiet || echo "ℹ️ NAT may already exist."

# ================================
# 🔥 5. Create firewall rule for port 6379
# ================================
echo "🔥 Creating firewall rule to allow TCP 6379 inbound to proxy VM..."
gcloud compute firewall-rules create "$FW_RULE_NAME" \
  --network="$NETWORK" \
  --allow=tcp:6379 \
  --target-tags=redis-proxy \
  --source-ranges=0.0.0.0/0 \
  --direction=INGRESS \
  --priority=1000 || echo "ℹ️ Firewall rule may already exist."

# Tag the VM so the rule applies
echo "🏷️ Tagging proxy VM with 'redis-proxy' network tag..."
gcloud compute instances add-tags "$PROXY_VM" \
  --zone="$ZONE" \
  --tags=redis-proxy

# ================================
# 🧰 6. Install redis-tools on VM
# ================================
echo "🧰 Installing redis-tools on proxy VM..."
gcloud compute ssh "$PROXY_VM" --zone="$ZONE" --command \
  "sudo apt-get update -y && sudo apt-get install -y redis-tools"

# ================================
# ✅ Done
# ================================
echo ""
echo "✅ All done!"
echo ""
echo "You can now SSH into the proxy VM and test Redis connectivity:"
echo "  gcloud compute ssh $PROXY_VM --zone=$ZONE"
echo ""
echo "Then run inside VM:"
echo "  REDIS_IP=\$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format='value(host)')"
echo "  redis-cli -h \$REDIS_IP -p 6379 ping"
echo ""
