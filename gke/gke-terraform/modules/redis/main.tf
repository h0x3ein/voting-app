resource "google_redis_instance" "cache" {
  project = var.project_id
  region  = var.region
  name    = "gke-redis-cache"


  connect_mode = "PRIVATE_SERVICE_ACCESS"

  authorized_network = var.network_id


  tier           = var.tier
  memory_size_gb = var.memory_size_gb

  port = 6379

  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}