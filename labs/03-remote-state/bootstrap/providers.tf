provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.expected_account_id]

  default_tags {
    tags = {
      Environment = "learning"
      Lab         = "03-remote-state"
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}
