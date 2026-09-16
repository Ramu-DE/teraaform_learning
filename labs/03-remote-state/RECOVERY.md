# Lab 03 Recovery and Failure Drills

Perform only against the provider-free lab workload. Preserve command output and timestamps as evidence, but never copy state content into evidence.

## Drill 1 — Migration rollback

If `terraform init -migrate-state` fails:

1. Stop; do not apply.
2. Preserve local and remote versions.
3. Determine whether the destination state object was written.
4. Compare `terraform state list` only after initializing deliberately against one backend.
5. Restore the generated backend files or local configuration, then retry with one authoritative state.

Do not delete either state merely to remove the error.

## Drill 2 — Lock contention

Use `workload/scripts/hold-lock.sh 20`, then run `terraform plan -lock-timeout=2s` in another terminal.

Expected evidence:

- First process owns the lock.
- Second process reports lock acquisition failure.
- Lock metadata identifies the operation/holder.
- Lock disappears after the first operation completes.
- A subsequent plan succeeds.

## Drill 3 — Suspected stale lock

1. Identify the lock ID and holder from Terraform's error.
2. Check CI jobs, terminals, and process ownership.
3. Wait through the expected operation duration.
4. Confirm no writer remains.
5. Prefer `terraform force-unlock <LOCK_ID>` through the configured backend only after confirmation.
6. Record who approved and why.

Do not blindly delete `.tflock` in S3. A lock that looks old can still belong to a slow process.

## Drill 4 — IAM denial

Remove or assume a role without one required permission and observe:

- No state read → initialization/plan cannot load state.
- No lock `PutObject` → lock acquisition fails.
- No lock `DeleteObject` → operation may finish but fail to release cleanly.
- No state `PutObject` → apply cannot persist new state and requires incident handling.

Restore the policy through a separately authorized administrative path. Do not broaden to `s3:*` as a shortcut.

## Drill 5 — Version inspection

List exact state versions:

```bash
./scripts/list-state-versions.sh <bucket> <state-key>
```

Select a noncurrent version and inspect it:

```bash
./scripts/inspect-state-version.sh <bucket> <state-key> <version-id>
```

Compare generation and component keys without exporting sensitive content elsewhere.

## Drill 6 — Restore historical content safely

Prerequisites:

- All Terraform runs stopped.
- Selected version inspected and documented.
- Current version ID recorded.
- `.tflock` absent.
- Workload remains disposable.

Run:

```bash
export CONFIRM_STATE_RESTORE='<bucket>/<state-key>@<version-id>'
./scripts/restore-state-version.sh <bucket> <state-key> <version-id>
unset CONFIRM_STATE_RESTORE
terraform plan
```

The script uploads the selected historical bytes as a new encrypted S3 version. It does not delete newer versions. The subsequent plan shows differences between restored state and actual desired configuration; decide whether to recover state forward or reconcile configuration.

## Drill 7 — Interrupted apply

The workload's resources are local `terraform_data`, but use the operational sequence applicable to cloud resources:

1. Stop competing mutations.
2. Preserve state versions and logs.
3. Inspect `terraform state list/show` and actual provider reality.
4. Fix the underlying error.
5. Run a normal plan; do not use `-target` reflexively.
6. Apply the smallest reviewed correction.
7. Verify a no-op plan.

## Drill 8 — State object accidentally deleted

With S3 versioning, an ordinary delete creates a delete marker rather than erasing prior versions. Do not remove versions. Inspect object versions/delete markers, select the correct version, and restore it as a new current version using the guarded script.

## Drill 9 — Local state accidentally recreated

A missing/disabled backend can lead to an empty local state. Symptoms include a plan proposing to create everything. Stop immediately. Reinitialize against the intended S3 backend and confirm state lineage/resources before planning again.

## Drill 10 — Backend unavailable

If S3, DNS, credentials, or network access is unavailable, do not bypass the backend with a new local state and apply. Treat the workload as temporarily read-only, restore backend access, then retry.

## Recovery completion criteria

- Correct state generation is current.
- Resource addresses match the configuration.
- No lock remains.
- A normal plan is understood and then converges to no-op.
- Version history remains available.
- Incident decisions and approvals are recorded without exposing state data.
