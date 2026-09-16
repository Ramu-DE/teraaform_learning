locals {
  list_statement = {
    Sid      = "ListExactStatePrefix"
    Effect   = "Allow"
    Action   = ["s3:ListBucket"]
    Resource = [local.bucket_arn]
    Condition = {
      StringEquals = {
        "s3:prefix" = [var.state_key, local.lock_key]
      }
    }
  }

  read_state_statement = {
    Sid      = "ReadState"
    Effect   = "Allow"
    Action   = ["s3:GetObject"]
    Resource = [local.state_arn]
  }

  write_state_statement = {
    Sid      = "WriteState"
    Effect   = "Allow"
    Action   = ["s3:GetObject", "s3:PutObject"]
    Resource = [local.state_arn]
  }

  lock_statement = {
    Sid      = "ManageNativeLockfile"
    Effect   = "Allow"
    Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    Resource = [local.lock_arn]
  }

  plan_policy = {
    Version   = "2012-10-17"
    Statement = [local.list_statement, local.read_state_statement, local.lock_statement]
  }

  apply_policy = {
    Version   = "2012-10-17"
    Statement = [local.list_statement, local.write_state_statement, local.lock_statement]
  }
}
