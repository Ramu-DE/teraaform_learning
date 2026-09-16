variable "aws_partition" {
  description = "AWS partition used to build S3 ARNs."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "This lab supports the aws and aws-us-gov partitions."
  }
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must satisfy S3 naming length and character rules."
  }
}

variable "aws_region" {
  description = "AWS region hosting the state bucket."
  type        = string
}

variable "state_key" {
  description = "Exact object key for the workload Terraform state."
  type        = string

  validation {
    condition     = !startswith(var.state_key, "/") && endswith(var.state_key, ".tfstate") && !strcontains(var.state_key, "..")
    error_message = "state_key must be a relative .tfstate key without parent traversal."
  }
}

variable "tags" {
  description = "Additional metadata for backend resources."
  type        = map(string)
  default     = {}
}

variable "enable_prevent_destroy" {
  description = "Enable lifecycle prevent_destroy on the S3 bucket. Set to false for testing."
  type        = bool
  default     = true
}
