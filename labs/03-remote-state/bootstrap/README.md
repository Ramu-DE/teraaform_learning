# Backend Bootstrap Root

This root creates S3 administrative infrastructure before any workload can use it as a backend. It intentionally starts with local state to solve the backend chicken-and-egg problem.

## Safety gate

Before any plan/apply, verify:

- `aws sts get-caller-identity` equals `expected_account_id`.
- Region and bucket name are intended.
- The account is an approved sandbox/workshop.
- Budget and cleanup ownership are confirmed.

The provider uses `allowed_account_ids`, and a separate caller-identity check provides defense in depth.

## Local checks

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform validate
terraform test
terraform -chdir=modules/state_backend test
```

## Apply only after approval

```bash
terraform plan -out=bootstrap.tfplan
terraform show bootstrap.tfplan
terraform apply bootstrap.tfplan
bucket=$(terraform output -raw bucket_name)
./scripts/verify-backend.sh "$bucket"
```

## Outputs

- S3 bucket, state key, and lock key.
- Partial backend object and rendered `backend.hcl`.
- Exact plan/apply state access policy JSON.

Outputs contain no credentials. State itself remains sensitive.

## Local bootstrap state

Keep the local bootstrap state protected throughout this temporary lab. Do not migrate it into the same workload key. A real platform should place bootstrap state in separately administered durable storage.

## Cleanup

`prevent_destroy` and versioned objects intentionally block casual deletion. Follow [`../CLEANUP.md`](../CLEANUP.md), including workload migration back to local, confirmed version deletion, and reviewed guard removal.
