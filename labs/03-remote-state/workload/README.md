# Provider-Free Workload for State Operations

This workload creates only built-in `terraform_data` entries so state migration and recovery can be learned without changing AWS workload resources. AWS is used only by the optional S3 backend.

## Local-first workflow

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform validate
terraform test
terraform plan -out=local.tfplan
terraform apply local.tfplan
terraform plan -detailed-exitcode
```

## Generated backend files

`backend.tf.example` is inactive source. `configure-backend.sh` copies it to `backend.tf` and writes mode-600 `backend.hcl`. Both generated files are ignored.

```bash
./scripts/configure-backend.sh <bucket> <region> <state-key>
./scripts/migrate-to-remote.sh
```

The migration remains interactive. Review which state is the source and destination rather than forcing a copy automatically.

## State versions

Change `generation` and apply to create distinct state versions. List and inspect with:

```bash
./scripts/list-state-versions.sh <bucket> <state-key>
./scripts/inspect-state-version.sh <bucket> <state-key> <version-id>
```

State inspection occurs in a restricted temporary directory and can still print sensitive values to your terminal.

## Native lock contention

`terraform_data.lock_probe` contains a lab-only local-exec sleep bounded to 60 seconds. It exists solely to keep a real Terraform operation holding the remote state lock long enough for another process to fail.

```bash
./scripts/hold-lock.sh 20
# In another terminal:
terraform plan -lock-timeout=2s
```

Do not copy this provisioner into production modules.

## Return to local

Before backend teardown:

```bash
./scripts/migrate-to-local.sh
terraform plan -detailed-exitcode
```

Then follow [`../CLEANUP.md`](../CLEANUP.md).

## Tests

```bash
terraform init -backend=false
terraform validate
terraform test
```

The tests use the local backend and do not contact AWS.
