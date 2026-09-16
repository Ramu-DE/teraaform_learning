# Lab 03: Remote State Management 🌐

## 📋 Overview

This lab teaches advanced state management with remote backends. You'll learn to set up S3-backed state, implement native S3 locking, perform safe migrations, and handle disaster recovery scenarios.

## 🎯 Learning Objectives

By the end of this lab, you will:

- ✅ Configure S3 remote backend with encryption
- ✅ Implement state locking without DynamoDB
- ✅ Migrate state safely between backends
- ✅ Use S3 versioning for state recovery
- ✅ Handle lock contention scenarios
- ✅ Perform disaster recovery operations
- ✅ Understand state lifecycle separation

## ⏱️ Estimated Time

**4-5 hours** (including setup, migration, testing, and recovery drills)

## 📁 Lab Structure

```
03-remote-state/
├── README.md                 # Main lab documentation
├── SECURITY.md              # Security considerations
├── RECOVERY.md              # Disaster recovery procedures
├── CLEANUP.md               # Safe cleanup instructions
│
├── bootstrap/               # Backend infrastructure
│   ├── README.md
│   ├── main.tf              # Bootstrap orchestrator
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   │
│   ├── modules/
│   │   └── state_backend/   # S3 backend module
│   │       ├── main.tf      # Bucket, encryption, policies
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   │
│   ├── tests/               # Bootstrap tests
│   │   └── bootstrap.tftest.hcl
│   │
│   └── scripts/
│       ├── verify-backend.sh
│       └── empty-versioned-bucket.sh
│
└── workload/                # Application state
    ├── README.md
    ├── main.tf              # Workload resources
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf.example   # Backend template
    ├── backend.hcl.example  # Backend config template
    │
    ├── tests/
    │   └── workload.tftest.hcl
    │
    └── scripts/
        ├── configure-backend.sh
        ├── migrate-to-remote.sh
        ├── migrate-to-local.sh
        ├── list-state-versions.sh
        ├── inspect-state-version.sh
        ├── restore-state-version.sh
        └── hold-lock.sh
```

## 🏗️ Architecture Overview

### Separation of Concerns

```
┌────────────────────────────────────────────────────────────────┐
│              STATE BACKEND ARCHITECTURE                         │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────┐       │
│  │         BOOTSTRAP (Local State)                    │       │
│  │                                                     │       │
│  │  Purpose: Create backend infrastructure            │       │
│  │  State: terraform.tfstate (local)                  │       │
│  │  Lifecycle: Long-lived, rarely changed             │       │
│  │                                                     │       │
│  │  Creates:                                          │       │
│  │  ├─ S3 Bucket (versioned, encrypted)              │       │
│  │  ├─ Bucket policies (TLS-only)                    │       │
│  │  ├─ IAM policies (least privilege)                │       │
│  │  └─ Backend configuration outputs                 │       │
│  │                                                     │       │
│  └──────────────────────┬──────────────────────────────       │
│                         │                                      │
│                         │ provides backend config              │
│                         ▼                                      │
│  ┌────────────────────────────────────────────────────┐       │
│  │         WORKLOAD (Remote State)                    │       │
│  │                                                     │       │
│  │  Purpose: Manage application infrastructure        │       │
│  │  State: S3 backend (remote)                        │       │
│  │  Lifecycle: Frequently changed                     │       │
│  │                                                     │       │
│  │  Uses:                                             │       │
│  │  ├─ S3 backend from bootstrap                     │       │
│  │  ├─ Native .tflock file locking                   │       │
│  │  ├─ S3 versioning for recovery                    │       │
│  │  └─ Encryption at rest                            │       │
│  │                                                     │       │
│  └────────────────────────────────────────────────────┘       │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### S3 Backend Components

```
┌────────────────────────────────────────────────────────────┐
│                    S3 BACKEND DETAILS                       │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  S3 Bucket: tf-lab03-state-{account-id}-{region}          │
│  ├─ Versioning: ENABLED                                   │
│  ├─ Encryption: AES256 (SSE-S3)                           │
│  ├─ Public Access: BLOCKED                                │
│  ├─ Ownership: BucketOwnerEnforced                        │
│  └─ Policy: TLS-only access                               │
│                                                             │
│  State Objects:                                            │
│  ├─ labs/03/workload/terraform.tfstate                    │
│  │  └─ Contains actual state (versioned)                  │
│  │                                                          │
│  └─ labs/03/workload/terraform.tfstate.tflock             │
│     └─ Lock file (temporary, deleted after release)       │
│                                                             │
│  IAM Policies:                                             │
│  ├─ Plan Policy (Read + Lock)                             │
│  │  • s3:GetObject on state                               │
│  │  • s3:PutObject, DeleteObject on lock                  │
│  │  • s3:ListBucket                                       │
│  │                                                          │
│  └─ Apply Policy (Read + Write + Lock)                    │
│     • s3:GetObject, PutObject on state                    │
│     • s3:PutObject, DeleteObject on lock                  │
│     • s3:ListBucket                                       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 🔄 State Migration Flow

```
┌────────────────────────────────────────────────────────────────┐
│            STATE MIGRATION: LOCAL → REMOTE                      │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PHASE 1: Local State                                          │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Working Directory                                │          │
│  │ ├─ main.tf, variables.tf, outputs.tf            │          │
│  │ ├─ terraform.tfstate (local file)               │          │
│  │ └─ .terraform/                                   │          │
│  │    └─ providers/                                 │          │
│  └─────────────────────────────────────────────────┘          │
│                         │                                       │
│                         │ terraform init -backend=false         │
│                         │ terraform apply                       │
│                         ▼                                       │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Local State Created                              │          │
│  │ • Resources exist in AWS                         │          │
│  │ • State stored locally                           │          │
│  │ • Backup: terraform state pull > backup.tfstate │          │
│  └─────────────────────────────────────────────────┘          │
│                         │                                       │
│  ──────────────────────────────────────────────────────────   │
│                         │                                       │
│  PHASE 2: Create Backend                                       │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Bootstrap Directory                              │          │
│  │ ├─ terraform apply (in bootstrap/)               │          │
│  │ │  Creates:                                      │          │
│  │ │  • S3 bucket (versioned, encrypted)            │          │
│  │ │  • Bucket policies                             │          │
│  │ │  • IAM policy documents                        │          │
│  │ └─ Outputs backend configuration                 │          │
│  └─────────────────────────────────────────────────┘          │
│                         │                                       │
│  ──────────────────────────────────────────────────────────   │
│                         │                                       │
│  PHASE 3: Configure Backend                                    │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Workload Directory                               │          │
│  │ ├─ Create backend.tf:                            │          │
│  │ │    terraform { backend "s3" {} }               │          │
│  │ │                                                 │          │
│  │ └─ Create backend.hcl:                           │          │
│  │      bucket       = "tf-lab03-state-..."         │          │
│  │      key          = "labs/03/workload/..."       │          │
│  │      region       = "us-east-1"                  │          │
│  │      encrypt      = true                         │          │
│  │      use_lockfile = true                         │          │
│  └─────────────────────────────────────────────────┘          │
│                         │                                       │
│  ──────────────────────────────────────────────────────────   │
│                         │                                       │
│  PHASE 4: Migrate State                                        │
│  ┌─────────────────────────────────────────────────┐          │
│  │ terraform init -migrate-state \                  │          │
│  │   -backend-config=backend.hcl                    │          │
│  │                                                   │          │
│  │ Prompt: "Copy state to new backend?"             │          │
│  │ Answer: yes                                      │          │
│  │                                                   │          │
│  │ Process:                                         │          │
│  │ 1. Read local terraform.tfstate                  │          │
│  │ 2. Upload to S3 bucket                           │          │
│  │ 3. Verify upload                                 │          │
│  │ 4. Keep local backup                             │          │
│  └─────────────────────────────────────────────────┘          │
│                         │                                       │
│                         ▼                                       │
│  ┌─────────────────────────────────────────────────┐          │
│  │ Remote State Active                              │          │
│  │ • State now in S3                                │          │
│  │ • All operations use S3                          │          │
│  │ • Lock file mechanism active                     │          │
│  │ • Versioning tracks changes                      │          │
│  └─────────────────────────────────────────────────┘          │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

## 🔒 Locking Mechanism

### Native S3 Locking

```
┌────────────────────────────────────────────────────────────┐
│          S3 NATIVE LOCKING (use_lockfile=true)             │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  NO DynamoDB Required! 🎉                                  │
│                                                             │
│  How it works:                                             │
│                                                             │
│  Process A starts (terraform apply)                        │
│       │                                                     │
│       ├─1─▶ Create lock file in S3                         │
│       │     └─ labs/03/workload/terraform.tfstate.tflock   │
│       │        Contents: { "ID": "uuid", "Operation": ... }│
│       │                                                     │
│       ├─2─▶ Perform operations                             │
│       │     └─ Read state, make changes, write state       │
│       │                                                     │
│       └─3─▶ Delete lock file                               │
│             └─ Lock released                                │
│                                                             │
│  Process B starts while A holds lock                       │
│       │                                                     │
│       ├─1─▶ Try to read lock file                          │
│       │     └─ Lock exists! (created by Process A)         │
│       │                                                     │
│       ├─2─▶ Wait (if lock_timeout set)                     │
│       │     └─ Retry periodically                          │
│       │                                                     │
│       └─3─▶ Timeout or success                             │
│             └─ Error or proceed when A releases            │
│                                                             │
│  Lock File Structure:                                      │
│  {                                                          │
│    "ID": "abc-def-123",                                    │
│    "Operation": "OperationTypeApply",                      │
│    "Info": "",                                             │
│    "Who": "user@hostname",                                 │
│    "Version": "1.5.0",                                     │
│    "Created": "2026-09-16T18:30:00Z",                      │
│    "Path": "labs/03/workload/terraform.tfstate"            │
│  }                                                          │
│                                                             │
│  Advantages over DynamoDB:                                 │
│  ✅ Simpler architecture                                   │
│  ✅ No additional service to manage                        │
│  ✅ Included in S3 costs                                   │
│  ✅ Same permissions as state file                         │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Lock Contention Scenario

```
┌────────────────────────────────────────────────────────────┐
│              LOCK CONTENTION EXAMPLE                        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Terminal A                      Terminal B                │
│     │                               │                      │
│     │ terraform apply               │                      │
│     ├─▶ Acquire lock ✓              │                      │
│     │   (create .tflock)            │                      │
│     │                               │                      │
│     │ Processing...                 │ terraform plan       │
│     │                               ├─▶ Try lock ✗         │
│     │                               │   Lock exists!       │
│     │                               │                      │
│     │                               │ Error: Failed to     │
│     │                               │ acquire state lock   │
│     │                               │                      │
│     │ Complete                      │                      │
│     ├─▶ Release lock ✓              │                      │
│     │   (delete .tflock)            │                      │
│     │                               │                      │
│     │                               │ terraform plan       │
│     │                               ├─▶ Acquire lock ✓    │
│     │                               │   Plan succeeds      │
│     │                               ├─▶ Release lock ✓    │
│                                                             │
│  With lock_timeout:                                        │
│                                                             │
│  terraform plan -lock-timeout=2m                           │
│  • Wait up to 2 minutes for lock                           │
│  • Retry periodically                                      │
│  • Succeed when lock released                              │
│  • Fail after timeout                                      │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 📦 State Versioning

### S3 Versioning Benefits

```
┌────────────────────────────────────────────────────────────┐
│              S3 STATE VERSIONING                            │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Every terraform apply creates a new version                │
│                                                             │
│  Version History:                                          │
│  ┌──────────────────────────────────────────────┐         │
│  │ Version 3 (Latest) - Generation 3            │         │
│  │ ├─ VersionId: 74N5H_ozFvGDZRgaL2E5...        │         │
│  │ ├─ Size: 10682 bytes                         │         │
│  │ ├─ Timestamp: 2026-09-16T18:42:13Z           │         │
│  │ └─ IsLatest: true                             │         │
│  └──────────────────────────────────────────────┘         │
│  ┌──────────────────────────────────────────────┐         │
│  │ Version 2 - Generation 2                     │         │
│  │ ├─ VersionId: kVkc7d9oZ9lKzBw0tXxx...        │         │
│  │ ├─ Size: 10682 bytes                         │         │
│  │ ├─ Timestamp: 2026-09-16T18:41:59Z           │         │
│  │ └─ IsLatest: false                            │         │
│  └──────────────────────────────────────────────┘         │
│  ┌──────────────────────────────────────────────┐         │
│  │ Version 1 (Initial) - Generation 1           │         │
│  │ ├─ VersionId: JRtyFHSEy2gitQezn7RT...        │         │
│  │ ├─ Size: 10682 bytes                         │         │
│  │ ├─ Timestamp: 2026-09-16T18:41:39Z           │         │
│  │ └─ IsLatest: false                            │         │
│  └──────────────────────────────────────────────┘         │
│                                                             │
│  Operations:                                               │
│  • List versions: ./scripts/list-state-versions.sh        │
│  • Inspect version: ./scripts/inspect-state-version.sh    │
│  • Restore version: ./scripts/restore-state-version.sh    │
│                                                             │
│  Use Cases:                                                │
│  ✓ Rollback after bad apply                               │
│  ✓ Audit state changes                                    │
│  ✓ Recover from corruption                                │
│  ✓ Compare state across time                              │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 🚨 Disaster Recovery

### Recovery Scenarios

```
┌────────────────────────────────────────────────────────────┐
│           DISASTER RECOVERY SCENARIOS                       │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Scenario 1: Accidental Bad Apply                          │
│  ──────────────────────────────────                        │
│  Problem: Applied wrong configuration, resources broken    │
│                                                             │
│  Solution:                                                 │
│  1. List state versions                                    │
│     ./scripts/list-state-versions.sh <bucket> <key>        │
│                                                             │
│  2. Inspect previous version                               │
│     ./scripts/inspect-state-version.sh \                   │
│       <bucket> <key> <version-id>                          │
│                                                             │
│  3. Restore previous version                               │
│     ./scripts/restore-state-version.sh \                   │
│       <bucket> <key> <version-id>                          │
│                                                             │
│  4. Review and re-apply                                    │
│     terraform plan                                         │
│     terraform apply                                        │
│                                                             │
│ ──────────────────────────────────────────────────────── │
│                                                             │
│  Scenario 2: State File Corruption                         │
│  ────────────────────────────────                          │
│  Problem: State file corrupted or invalid                  │
│                                                             │
│  Solution:                                                 │
│  1. Download previous version from S3                      │
│  2. Verify integrity                                       │
│  3. Restore as latest version                              │
│  4. Refresh and reconcile                                  │
│                                                             │
│ ──────────────────────────────────────────────────────── │
│                                                             │
│  Scenario 3: Stale Lock                                    │
│  ─────────────────────                                     │
│  Problem: Lock file not released (process crashed)         │
│                                                             │
│  Solution:                                                 │
│  1. Verify no active processes                             │
│  2. Manually delete lock file from S3:                     │
│     aws s3 rm s3://<bucket>/<key>.tflock                   │
│  3. Proceed with operation                                 │
│                                                             │
│ ──────────────────────────────────────────────────────── │
│                                                             │
│  Scenario 4: Complete Backend Loss                         │
│  ────────────────────────────────                          │
│  Problem: S3 bucket deleted or inaccessible                │
│                                                             │
│  Solution:                                                 │
│  1. Restore from local backup:                             │
│     cp pre-migration.backup.tfstate terraform.tfstate      │
│  2. Remove backend configuration                           │
│  3. Continue with local state                              │
│  4. Recreate backend when ready                            │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 📖 Step-by-Step Guide

### Phase 1: Local Validation (No AWS Changes)

```bash
cd labs/03-remote-state/bootstrap

# Validate configuration
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test

# Validate workload module
cd ../workload
terraform init -backend=false
terraform validate
terraform test
```

### Phase 2: Account Verification

```bash
# Check AWS identity
aws sts get-caller-identity

# Verify region
echo $AWS_REGION

# Check budgets (optional)
aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text)
```

### Phase 3: Build Local Workload State

```bash
cd labs/03-remote-state/workload

# Configure variables
cp terraform.tfvars.example terraform.tfvars

# Initialize and create local state
terraform init -backend=false
terraform plan -out=local.tfplan
terraform apply local.tfplan

# Verify
terraform state list
terraform output

# Create backup
umask 077
terraform state pull > pre-migration.backup.tfstate
```

### Phase 4: Create Backend

```bash
cd ../bootstrap

# Configure
cp terraform.tfvars.example terraform.tfvars

# Create backend infrastructure
terraform init -backend=false
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan

# Verify backend
bucket=$(terraform output -raw bucket_name)
./scripts/verify-backend.sh "$bucket"

# Review IAM policies
terraform output -raw plan_policy_json | jq .
terraform output -raw apply_policy_json | jq .
```

### Phase 5: Migrate to Remote State

```bash
cd ../workload

# Configure backend
../bootstrap/../../workload/scripts/configure-backend.sh \
  "$(cd ../bootstrap && terraform output -raw bucket_name)" \
  "us-east-1" \
  "labs/03/workload/terraform.tfstate"

# Review generated files
cat backend.tf
cat backend.hcl

# Migrate
terraform init -migrate-state -backend-config=backend.hcl
# Answer "yes" when prompted

# Verify migration
terraform state list
terraform plan -detailed-exitcode  # Should show no changes
```

### Phase 6: Create State Versions

```bash
# Apply with different generations
terraform apply -var='generation=2' -auto-approve
terraform apply -var='generation=3' -auto-approve

# List versions
./scripts/list-state-versions.sh \
  "$(cd ../bootstrap && terraform output -raw bucket_name)" \
  "labs/03/workload/terraform.tfstate"

# Inspect old version
./scripts/inspect-state-version.sh \
  "<bucket>" "<key>" "<version-id>"
```

### Phase 7: Test Lock Contention

```bash
# Terminal A: Hold lock for 20 seconds
./scripts/hold-lock.sh 20

# Terminal B (while A is running): Try to acquire lock
terraform plan -lock-timeout=2s
# Should fail with lock error

# After A completes, verify lock released
terraform plan  # Should succeed
```

### Phase 8: Recovery Drill

Follow [RECOVERY.md](./RECOVERY.md) for detailed recovery procedures.

### Phase 9: Clean Up

Follow [CLEANUP.md](./CLEANUP.md) for safe cleanup:

```bash
# 1. Migrate state back to local
cd workload
./scripts/migrate-to-local.sh

# 2. Verify local state
terraform plan -detailed-exitcode

# 3. Destroy workload (optional)
terraform destroy

# 4. Empty bucket versions
cd ../bootstrap
./scripts/empty-versioned-bucket.sh <bucket-name>

# 5. Remove prevent_destroy and destroy backend
# (Follow CLEANUP.md instructions)
```

## 🔐 Security Considerations

See [SECURITY.md](./SECURITY.md) for complete security documentation.

### Key Security Features

✅ **Encryption:**
- State encrypted at rest (AES256)
- TLS required for all S3 operations

✅ **Access Control:**
- Least privilege IAM policies
- Separate plan/apply permissions
- No public access

✅ **Auditing:**
- S3 server access logging enabled
- CloudTrail for API calls
- Versioning for audit trail

✅ **Lifecycle Management:**
- Bootstrap and workload separation
- Prevent_destroy on bucket
- Explicit cleanup procedures

## 🎓 Key Lessons

1. **Backend Lifecycle Separation**
   - Bootstrap infrastructure ≠ workload infrastructure
   - Different lifecycles, different states
   - Never destroy backend with active workloads

2. **Native S3 Locking**
   - No DynamoDB required
   - Simpler architecture
   - Same cost as state storage

3. **State Migration is Safe**
   - Always backup before migration
   - No resource recreation needed
   - State location ≠ resources

4. **Versioning Enables Recovery**
   - Every apply creates a version
   - Can rollback to any point
   - Inspect without restoring

5. **Locking Prevents Conflicts**
   - Only one writer at a time
   - Lock timeout for stuck locks
   - Manual override when needed

## 📈 Next Steps

After completing this lab:

1. ✅ Practice recovery scenarios
2. ✅ Set up remote state for real projects
3. ✅ Implement state backend in CI/CD
4. ✅ Explore workspaces for multi-environment
5. ✅ Study advanced state management patterns

## 📚 Additional Resources

- [S3 Backend Documentation](https://www.terraform.io/language/settings/backends/s3)
- [State Locking](https://www.terraform.io/language/state/locking)
- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/configuration)

---

**🎉 Congratulations!** You've mastered remote state management and are now ready for production Terraform workflows!

**Repository:** [github.com/Ramu-DE/terraform_learning](https://github.com/Ramu-DE/terraform_learning)
