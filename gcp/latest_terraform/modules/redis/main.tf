resource "google_redis_instance" "redis" {

  name               = var.redis_name
  memory_size_gb     = var.redis_size_gb
  authorized_network = var.vote_vpc
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
}