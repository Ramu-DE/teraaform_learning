output "generation" {
  description = "Current intentional state generation."
  value       = terraform_data.summary.output.generation
}

output "component_contracts" {
  description = "Provider-free component objects stored in Terraform state."
  value = {
    for name, component in terraform_data.component :
    name => component.output
  }
}

output "state_summary" {
  description = "Compact state content used during migration and recovery checks."
  value       = terraform_data.summary.output
}

output "state_fingerprint" {
  description = "Deterministic fingerprint of desired workload content, excluding opaque resource IDs."
  value = sha256(jsonencode({
    project    = var.project_name
    generation = var.generation
    components = var.components
  }))
}
