output "bucket_name" {
  description = "S3 bucket created for Terraform state."
  value       = module.state_backend.bucket_name
}

output "state_key" {
  description = "Exact workload state object key."
  value       = module.state_backend.state_key
}

output "lock_key" {
  description = "Native S3 lockfile object key."
  value       = module.state_backend.lock_key
}

output "backend_config" {
  description = "Non-secret values required for the workload S3 backend."
  value       = module.state_backend.backend_config
}

output "backend_hcl" {
  description = "Rendered partial backend configuration; write this to workload/backend.hcl."
  value       = module.state_backend.backend_hcl
}

output "plan_policy_json" {
  description = "Least-privilege policy for state read plus native lock acquisition during plan."
  value       = module.state_backend.plan_policy_json
}

output "apply_policy_json" {
  description = "Least-privilege policy for state update plus native lock acquisition during apply."
  value       = module.state_backend.apply_policy_json
}
