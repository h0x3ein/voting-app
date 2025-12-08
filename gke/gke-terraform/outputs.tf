# =============================================================================
# Project Outputs
# =============================================================================

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

# =============================================================================
# GKE Cluster Outputs
# =============================================================================

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = var.cluster_name
}

# =============================================================================
# Redis (Memorystore) Outputs
# =============================================================================

output "redis_host" {
  description = "Private IP address of Redis instance"
  value       = module.redis.host
}

output "redis_port" {
  description = "Port of Redis instance"
  value       = module.redis.port
}

# =============================================================================
# Cloud SQL Outputs
# =============================================================================

output "cloud_sql_instance_connection_name" {
  description = "Cloud SQL instance connection name (for proxy sidecar)"
  value       = module.cloud_sql.instance_connection_name
}

output "cloud_sql_private_ip" {
  description = "Private IP address of Cloud SQL instance"
  value       = module.cloud_sql.private_ip_address
}

output "cloud_sql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = module.cloud_sql.instance_name
}

# =============================================================================
# Network Outputs
# =============================================================================

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.network.network_name
}

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = module.network.network_id
}

# =============================================================================
# Service Account Outputs
# =============================================================================

output "gke_node_sa_email" {
  description = "Email of the GKE node service account"
  value       = module.project.gke_node_sa_email
}

output "cloud_sql_sa_email" {
  description = "Email of the Cloud SQL service account (for Workload Identity)"
  value       = module.project.cloud_sql_sa_email
}
