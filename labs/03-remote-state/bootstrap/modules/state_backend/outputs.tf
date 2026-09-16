output "bucket_name" {
  description = "S3 bucket created for Terraform state."
  value       = aws_s3_bucket.this.id
}

output "state_key" {
  description = "Exact state object key."
  value       = var.state_key
}

output "lock_key" {
  description = "Exact native lockfile object key."
  value       = local.lock_key
}

output "backend_config" {
  description = "Non-secret partial S3 backend values."
  value = {
    bucket       = aws_s3_bucket.this.id
    key          = var.state_key
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

output "backend_hcl" {
  description = "Rendered non-secret HCL suitable for terraform init -backend-config."
  value = join("\n", [
    "bucket       = \"${aws_s3_bucket.this.id}\"",
    "key          = \"${var.state_key}\"",
    "region       = \"${var.aws_region}\"",
    "encrypt      = true",
    "use_lockfile = true",
    "",
  ])
}

output "plan_policy_json" {
  description = "Policy for state read and native lock management during plan."
  value       = jsonencode(local.plan_policy)
}

output "apply_policy_json" {
  description = "Policy for state update and native lock management during apply."
  value       = jsonencode(local.apply_policy)
}
