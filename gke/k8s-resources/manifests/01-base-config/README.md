### Option 2: Manual Step-by-Step

```bash
# Set all required variables
export PROJECT_ID=$(gcloud config get-value project)
export REDIS_HOST=$(cd ../../gke-terraform && terraform output -raw redis_host)
export CLOUD_SQL_CONNECTION_NAME=$(cd ../../gke-terraform && terraform output -raw cloud_sql_instance_connection_name)
export DB_PASSWORD="vote@pass123456"

# Apply configuration
./apply.sh
