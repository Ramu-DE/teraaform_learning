output "contract" {
  description = "Normalized service contract for sibling modules and root consumers."
  value       = terraform_data.this.input
}

output "resource_id" {
  description = "Opaque identifier of the built-in learning resource; consumers should normally use contract instead."
  value       = terraform_data.this.id
}
