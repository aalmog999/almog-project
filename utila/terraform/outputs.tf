output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = local.cluster_name
}

output "cluster_region" {
  description = "Region containing the GKE cluster."
  value       = var.region
}

output "cluster_endpoint" {
  description = "GKE API endpoint."
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate."
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "node_service_account" {
  description = "Service account used by GKE nodes."
  value       = module.gke.service_account
}

output "network_name" {
  description = "Name of the VPC."
  value       = local.network_name
}

output "subnet_name" {
  description = "Name of the GKE subnet."
  value       = local.subnet_name
}

output "pods_range_name" {
  description = "Name of the secondary pod range."
  value       = local.pods_range_name
}

output "services_range_name" {
  description = "Name of the secondary Service range."
  value       = local.services_range_name
}

output "get_credentials_command" {
  description = "Command used to configure kubectl."

  value = join(" ", [
    "gcloud container clusters get-credentials",
    local.cluster_name,
    "--region",
    var.region,
    "--project",
    var.project_id,
  ])
}