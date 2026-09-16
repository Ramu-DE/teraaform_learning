data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  bucket_name = "${var.bucket_prefix}-${var.expected_account_id}-${var.aws_region}"
}

module "state_backend" {
  source = "./modules/state_backend"

  aws_partition = data.aws_partition.current.partition
  bucket_name   = local.bucket_name
  aws_region    = var.aws_region
  state_key     = var.state_key
  tags = {
    AccountId = var.expected_account_id
    Purpose   = "terraform-remote-state"
  }
}

check "expected_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.expected_account_id
    error_message = "Active AWS account does not match expected_account_id. Stop before applying."
  }
}
