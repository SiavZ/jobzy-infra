output "instance_id" {
  description = "Redis instance ID"
  value       = google_redis_instance.redis.id
}

output "instance_name" {
  description = "Redis instance name"
  value       = google_redis_instance.redis.name
}

output "host" {
  description = "Redis host IP address"
  value       = google_redis_instance.redis.host
}

output "port" {
  description = "Redis port"
  value       = google_redis_instance.redis.port
}

output "current_location_id" {
  description = "Current location ID"
  value       = google_redis_instance.redis.current_location_id
}

output "connection_string" {
  description = "Redis connection string"
  value       = "${google_redis_instance.redis.host}:${google_redis_instance.redis.port}"
}
