output "host" {
  description = "The IP address of the Redis instance."
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "The port of the Redis instance (default is 6379)."
  value       = google_redis_instance.cache.port
}