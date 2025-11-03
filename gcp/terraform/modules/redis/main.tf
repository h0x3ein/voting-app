# Create a private Redis instance
resource "google_redis_instance" "redis" {
  project        = var.project_id
  name           = var.redis_name
  region         = var.region
  tier           = var.redis_tier
  memory_size_gb = var.redis_size_gb

  # Attach to the private network (PSA)
  authorized_network = var.network_self_link

  # Private Service Access required
  connect_mode = "PRIVATE_SERVICE_ACCESS"

  # Optional configuration
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  # Optional maintenance window
  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  # Optional: Add labels for tracking
  labels = {
    environment = var.environment
    purpose     = "redis"
  }
}