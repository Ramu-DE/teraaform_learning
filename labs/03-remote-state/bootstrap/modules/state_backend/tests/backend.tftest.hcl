mock_provider "aws" {}

run "secure_backend_plan" {
  command = plan

  variables {
    bucket_name = "tf-lab03-state-123456789012-us-east-1"
    aws_region  = "us-east-1"
    state_key   = "labs/03/workload/terraform.tfstate"
    tags = {
      Purpose = "terraform-remote-state"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "The state bucket must not force-delete objects."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "State recovery requires bucket versioning."
  }

  assert {
    condition = anytrue(flatten([
      for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule : [
        for encryption_default in rule.apply_server_side_encryption_by_default :
        encryption_default.sse_algorithm == "AES256"
      ]
    ]))
    error_message = "The state bucket must explicitly enable server-side encryption."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "Every S3 public-access block control must be enabled."
  }

  assert {
    condition     = output.backend_config.use_lockfile && output.backend_config.encrypt
    error_message = "Rendered backend configuration must enable encryption and native lockfiles."
  }

  assert {
    condition     = output.lock_key == "labs/03/workload/terraform.tfstate.tflock"
    error_message = "Native lockfile key must be the state key plus .tflock."
  }
}

run "least_privilege_policy_plan" {
  command = plan

  variables {
    bucket_name = "tf-lab03-state-123456789012-us-east-1"
    aws_region  = "us-east-1"
    state_key   = "labs/03/workload/terraform.tfstate"
  }

  assert {
    condition     = contains(jsondecode(output.apply_policy_json).Statement[1].Action, "s3:PutObject")
    error_message = "Apply policy must permit writing the exact state object."
  }

  assert {
    condition     = !contains(jsondecode(output.plan_policy_json).Statement[1].Action, "s3:PutObject")
    error_message = "Plan policy must not permit writing the state object."
  }

  assert {
    condition     = contains(jsondecode(output.plan_policy_json).Statement[2].Action, "s3:DeleteObject")
    error_message = "A locking plan needs permission to release the exact .tflock object."
  }

  assert {
    condition     = !contains(jsondecode(output.apply_policy_json).Statement[1].Action, "s3:DeleteObject")
    error_message = "Terraform does not require DeleteObject on the state object."
  }
}

run "reject_unsafe_state_key" {
  command = plan

  variables {
    bucket_name = "tf-lab03-state-123456789012-us-east-1"
    aws_region  = "us-east-1"
    state_key   = "../terraform.tfstate"
  }

  expect_failures = [var.state_key]
}
