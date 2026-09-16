output "deployment_name" {
  description = "Deterministic project and environment identifier."
  value       = terraform_data.deployment.output.name
}

output "service_configurations" {
  description = "Normalized configuration for each logical service tier."
  value = {
    for name, service in terraform_data.service : name => service.output
  }
}

output "public_service_names" {
  description = "Sorted names of service tiers modeled as public."
  value       = local.public_service_names
}

output "private_service_names" {
  description = "Sorted names of service tiers modeled as private."
  value       = local.private_service_names
}

output "total_replicas" {
  description = "Total desired replicas across all logical service tiers."
  value       = terraform_data.deployment.output.total_replicas
}

output "common_tags" {
  description = "Final metadata after mandatory tags override additional values."
  value       = local.common_tags
}
