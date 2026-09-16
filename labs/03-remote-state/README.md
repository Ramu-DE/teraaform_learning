# Lab 03 — S3 Remote State, Native Locking, Migration, and Recovery

## Status in this workspace

The complete lab is implemented for local validation. Real AWS apply is **gated** because read-only account checks found a workshop account but no visible budget safeguard. No S3 backend has been created by this lab yet.

## Goals

- Separate backend bootstrap from workload state.
- Create a private, encrypted, versioned S3 backend.
- Use S3-native `.tflock` locking rather than deprecated DynamoDB locking.
- Generate exact state/lock IAM policy documents.
- Migrate provider-free local state to S3 and back without recreation.
- Demonstrate lock contention safely.
- Inspect and restore S3 state versions.
- Practice stale-lock, failed migration, IAM denial, and cleanup procedures.

## Architecture

```text
bootstrap/ (local state)                 workload/ (starts local)
┌─────────────────────────┐              ┌──────────────────────────┐
│ expected account check  │              │ terraform_data workload  │
│ state_backend module    │              │ generation changes       │
│ ├─ private S3 bucket    │◄── migrate ──│ backend.tf (generated)   │
│ ├─ versioning + AES256  │              │ backend.hcl (generated)  │
│ ├─ TLS-only policy      │              │ native .tflock           │
│ └─ IAM policy outputs   │              └──────────────────────────┘
└─────────────────────────┘
```

The bootstrap and workload never share one Terraform state. Destroying a workload must not destroy its backend, and a workload should not have permission to reconfigure backend security.

## Layout

```text
03-remote-state/
├── README.md
├── SECURITY.md
├── RECOVERY.md
├── CLEANUP.md
├── bootstrap/
│   ├── README.md
│   ├── modules/state_backend/
│   ├── tests/
│   └── scripts/
└── workload/
    ├── README.md
    ├── backend.tf.example
    ├── backend.hcl.example
    ├── tests/
    └── scripts/
```

## Phase 1 — Local validation (no AWS mutation)

```bash
cd bootstrap
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
terraform -chdir=modules/state_backend init -backend=false
terraform -chdir=modules/state_backend validate
terraform -chdir=modules/state_backend test

cd ../workload
terraform init -backend=false
terraform validate
terraform test
```

Mocked bootstrap tests do not prove IAM permissions or AWS service behavior. They prove the planned configuration contract.

## Phase 2 — Account and budget gate

Repeat and record:

```bash
aws sts get-caller-identity
printf 'AWS_REGION=%s AWS_DEFAULT_REGION=%s\n' "$AWS_REGION" "$AWS_DEFAULT_REGION"
aws budgets describe-budgets --account-id "$(aws sts get-caller-identity --query Account --output text)"
```

Proceed only when all are true:

- Account is explicitly approved for this lab.
- Region is intended.
- Current role is understood and short-lived.
- Budget/charge ownership is confirmed.
- Bucket name is not owned by another project.
- Cleanup time is available.

## Phase 3 — Build local workload state first

```bash
cd workload
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform plan -out=local.tfplan
terraform apply local.tfplan
terraform state list
terraform output
terraform plan -detailed-exitcode
```

Exit code `0` proves convergence. Record a protected backup before migration:

```bash
umask 077
terraform state pull > pre-migration.backup.tfstate
```

The backup is sensitive and ignored by the workload `.gitignore`.

## Phase 4 — Create the backend (AWS mutation)

Only after Phase 2 is approved:

```bash
cd ../bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform test
terraform plan -out=bootstrap.tfplan
terraform show bootstrap.tfplan
terraform apply bootstrap.tfplan
```

Verify controls and inspect outputs:

```bash
bucket=$(terraform output -raw bucket_name)
./scripts/verify-backend.sh "$bucket"
terraform output -raw plan_policy_json | python3 -m json.tool
terraform output -raw apply_policy_json | python3 -m json.tool
```

## Phase 5 — Configure and migrate workload state

From `workload/`, use the verified bootstrap outputs:

```bash
../workload/scripts/configure-backend.sh \
  "tf-lab03-state-487479758924-us-east-1" \
  "us-east-1" \
  "labs/03/workload/terraform.tfstate"

./scripts/migrate-to-remote.sh
terraform state list
terraform plan -detailed-exitcode
```

Read the migration prompt. Do not use `-force-copy` until you understand source and destination state lineage. After migration, the plan should be no-op and resource addresses unchanged.

## Phase 6 — Create and inspect versions

Change `generation` from 1 to 2, review and apply. Repeat for generation 3 if desired. Each state write produces a new S3 object version.

```bash
terraform apply -var='generation=2'
./scripts/list-state-versions.sh \
  tf-lab03-state-487479758924-us-east-1 \
  labs/03/workload/terraform.tfstate
```

Inspect a historical version without restoring it:

```bash
./scripts/inspect-state-version.sh <bucket> <state-key> <version-id>
```

## Phase 7 — Lock contention drill

Terminal A:

```bash
./scripts/hold-lock.sh 20
```

Terminal B while A sleeps:

```bash
terraform plan -lock-timeout=2s
```

Terminal B must fail to acquire the lock. After Terminal A completes, the `.tflock` object should be gone and a normal plan should succeed. The local-exec sleep is deliberately lab-only and must not be copied into production code.

## Phase 8 — Recovery and failure drills

Follow [RECOVERY.md](RECOVERY.md). Restore only in this disposable provider-free workload and only after inspecting the selected version.

## Phase 9 — Return to local and clean up

Follow [CLEANUP.md](CLEANUP.md) in order. The critical sequence is:

1. Stop competing Terraform processes.
2. Migrate workload state back to local.
3. Verify local state and no-op plan.
4. Confirm remote state is no longer authoritative.
5. Empty every version/delete marker with explicit confirmation.
6. Deliberately remove the bucket's `prevent_destroy` guard.
7. Destroy bootstrap resources and verify deletion.
8. Remove sensitive local artifacts.

## Acceptance criteria

### Local implementation

- [ ] Bootstrap root and child module format, initialize, validate, and pass mocked tests.
- [ ] Workload format, initialize, validate, and pass provider-free tests.
- [ ] Scripts have syntax checks and executable permissions.
- [ ] No generated state/backend/plan files are committed.

### AWS exercise (gated)

- [ ] Account, region, role, and budget owner are recorded.
- [ ] Bootstrap plan targets only the intended account and bucket.
- [ ] Bucket versioning, AES256 encryption, ownership, public block, and TLS denial are verified through AWS APIs.
- [ ] Local state migrates to S3 with no resource recreation.
- [ ] Backend uses `use_lockfile = true`; no DynamoDB table exists.
- [ ] Concurrent process fails to obtain the lock.
- [ ] At least two state object versions exist and one is inspected.
- [ ] Recovery is rehearsed as a new object version and followed by a reviewed plan.
- [ ] State migrates back to local before backend cleanup.
- [ ] Bucket protection blocks accidental destroy.
- [ ] Confirmed cleanup removes all versions and backend resources.

## Key lessons

- A backend is administrative infrastructure with a different lifecycle from workloads.
- Locking prevents concurrent writers; it does not replace review, backups, or IAM.
- Versioning enables recovery but does not choose the correct version for you.
- A “read-only plan role” still needs write/delete permissions on the exact lock object.
- State migration changes storage, not resource addresses or remote infrastructure.
- `prevent_destroy` is a guardrail that requires a deliberate, reviewed cleanup path.
