# State Backend Child Module

Creates the administrative S3 storage used by the Lab 03 workload backend.

## Resources

- S3 bucket with `force_destroy = false` and `prevent_destroy = true`.
- Bucket-owner-enforced ownership controls.
- Complete S3 public-access block.
- Enabled versioning.
- Explicit SSE-S3 AES256 encryption.
- TLS-only bucket policy.

## Inputs

- `bucket_name`: globally unique S3 bucket.
- `aws_region`: backend region rendered for consumers.
- `state_key`: exact workload state key.
- `aws_partition`: `aws` or `aws-us-gov` for ARN generation.
- `tags`: additional metadata.

## Outputs

- Bucket, state key, and `.tflock` key.
- Structured and rendered partial backend configuration.
- Exact plan and apply IAM policy JSON.

The module deliberately does not create IAM users/roles or trust policies. Identity lifecycle and federation belong to the organization/platform layer.

## Tests

Mocked tests verify versioning, encryption, public-access controls, non-force deletion, native lock configuration, policy differences, and unsafe key rejection:

```bash
terraform init -backend=false
terraform validate
terraform test
```

Mock tests do not call AWS and cannot prove actual account permissions or service controls.

## Destruction

The default module blocks destruction. Follow [`../../../CLEANUP.md`](../../../CLEANUP.md) to migrate state, empty all versions, review a destroy plan, temporarily remove the guard, and restore source afterward.
