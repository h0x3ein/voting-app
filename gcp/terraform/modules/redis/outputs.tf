#######################################
# 📤 Redis Outputs
#######################################

output "redis_host" {
  description = "The internal IP address of the Redis instance."
  value       = google_redis_instance.redis.host
}

output "redis_port" {
  description = "The port number Redis is listening on."
  value       = google_redis_instance.redis.port
}

output "redis_name" {
  description = "The name of the Redis instance."
  value       = google_redis_instance.redis.name
}

output "redis_region" {
  description = "The region where Redis is deployed."
  value       = google_redis_instance.redis.region
}