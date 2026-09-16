# Lab 03 Cleanup Runbook

Backend cleanup is destructive. Do not run it while S3 is authoritative or while another process may be using the state.

## Option A — Retain the backend

For continued labs, retain the protected bucket and local bootstrap state. Keep cost ownership, access review, and lifecycle documented. Remove only temporary workload plans/backups that are no longer required.

## Option B — Full lab teardown

### 1. Stop writers and verify the lock

Stop all terminals and CI runs except the cleanup operator. A normal workload plan must run or fail for an understood reason. Confirm the `.tflock` object is absent.

### 2. Migrate state back to local

From `workload/`:

```bash
./scripts/migrate-to-local.sh
terraform state list
terraform plan -detailed-exitcode
```

The plan should exit `0`. Protect the resulting local state with mode 600 and a secure backup until cleanup is complete.

### 3. Destroy workload entries if the lab is ending

```bash
terraform destroy
terraform state list
```

The list must be empty.

### 4. Confirm remote state is no longer authoritative

Record the bucket, state key, latest version ID, and successful local migration. Ensure no other root uses this bucket/key.

### 5. Empty every S3 object version

This is permanent deletion and is intentionally confirmation-gated:

```bash
cd ../bootstrap
bucket=$(terraform output -raw bucket_name)
export CONFIRM_EMPTY_VERSIONED_BUCKET="$bucket"
./scripts/empty-versioned-bucket.sh "$bucket"
unset CONFIRM_EMPTY_VERSIONED_BUCKET
aws s3api list-object-versions --bucket "$bucket"
```

The script aborts above 1000 versions rather than partially cleaning an unexpectedly large bucket. For a larger real backend, use a reviewed lifecycle/retention and batched deletion procedure.

### 6. Deliberately remove destroy protection

The module contains:

```hcl
lifecycle {
  prevent_destroy = true
}
```

After peer/self review confirms steps 1–5, change it to `false` temporarily. Run `terraform plan -destroy` and verify only this lab's backend resources are affected.

Do not normalize this change into the default module. It exists only for the one-time teardown.

### 7. Destroy the bootstrap

```bash
terraform destroy
```

Verify the bucket no longer exists. Restore `prevent_destroy = true` in source after the lab, even though no resource remains.

### 8. Remove generated local artifacts

Only after successful teardown and any required evidence retention:

```bash
cd ../workload
rm -rf .terraform terraform.tfstate terraform.tfstate.backup \
  backend.tf backend.hcl terraform.tfvars pre-migration.backup.tfstate

cd ../bootstrap
rm -rf .terraform terraform.tfstate terraform.tfstate.backup \
  terraform.tfvars bootstrap.tfplan
```

Review `pwd` and filenames before deletion. Never use broad recursive cleanup against an unknown directory.

## Teardown evidence

- Workload state migrated local before deletion.
- Workload destroyed or deliberately retained elsewhere.
- Lock absent.
- Versioned bucket emptied with exact confirmation.
- Destroy plan reviewed after guard removal.
- Bootstrap destroy succeeded.
- S3 bucket lookup confirms absence.
- Source restored with `prevent_destroy = true`.
- Sensitive local artifacts removed or transferred to approved storage.
