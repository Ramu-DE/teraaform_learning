variable "expected_account_id" {
  description = "Twelve-digit AWS account ID that is allowed to receive the backend."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "expected_account_id must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "AWS region in which the S3 backend bucket is created."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid commercial or GovCloud-style AWS region name."
  }
}

variable "bucket_prefix" {
  description = "Globally unique bucket-name prefix; account ID and region are appended."
  type        = string
  default     = "tf-lab03-state"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,29}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-30 lowercase letters, numbers, or hyphens."
  }
}

variable "state_key" {
  description = "Exact S3 object key used by the provider-free workload state."
  type        = string
  default     = "labs/03/workload/terraform.tfstate"

  validation {
    condition     = !startswith(var.state_key, "/") && endswith(var.state_key, ".tfstate") && !strcontains(var.state_key, "..")
    error_message = "state_key must be a relative .tfstate object key without parent traversal."
  }
}

variable "owner" {
  description = "Accountable owner recorded in tags."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) >= 3
    error_message = "owner must contain at least three non-whitespace characters."
  }
}
