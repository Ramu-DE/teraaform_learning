mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:role/terraform-test"
      user_id    = "terraform-test"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      id     = "tf-lab03-state-123456789012-us-east-1"
      bucket = "tf-lab03-state-123456789012-us-east-1"
      arn    = "arn:aws:s3:::tf-lab03-state-123456789012-us-east-1"
    }
  }
}

run "account_bound_backend_plan" {
  command = plan

  variables {
    expected_account_id = "123456789012"
    aws_region          = "us-east-1"
    owner               = "platform-team"
  }

  override_resource {
    target = module.state_backend.aws_s3_bucket.this
    override_during = plan
    values = {
      id = "tf-lab03-state-123456789012-us-east-1"
    }
  }

  # Test will verify bucket naming and configuration are correct
  assert {
    condition     = output.bucket_name == "tf-lab03-state-123456789012-us-east-1"
    error_message = "Bucket naming must bind prefix, expected account, and region."
  }

  assert {
    condition     = output.backend_config.use_lockfile == true
    error_message = "Root output must preserve native lockfile configuration."
  }
}
