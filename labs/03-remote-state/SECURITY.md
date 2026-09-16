# Lab 03 Security Model

## State is sensitive

Terraform state and saved plans can contain resource attributes, generated values, identifiers, and secrets even when outputs are marked `sensitive`. Anyone who can read the S3 state object should be treated as having privileged workload access. Never publish state, attach it to tickets, paste it into chat, or commit it.

This lab uses only provider-free workload values, but the backend must be designed as though future state contains secrets.

## Verified session context

Read-only checks on 2026-09-16 found:

- Account: `487479758924`
- Principal type: assumed workshop shared role on EC2
- Environment: DevOps Agent Workshop
- Region environment: `us-east-1`
- Account alias: none
- Visible AWS Budgets: none returned; budget safeguard unverified

These values are a snapshot, not permanent authorization. Repeat checks before every real apply.

## Account guardrails

The bootstrap requires `expected_account_id` twice:

1. AWS provider `allowed_account_ids` rejects another account during provider configuration.
2. A caller-identity check compares the active account with the expected value.

Run before plan/apply:

```bash
aws sts get-caller-identity
printf 'AWS_REGION=%s AWS_DEFAULT_REGION=%s\n' "$AWS_REGION" "$AWS_DEFAULT_REGION"
aws budgets describe-budgets --account-id 487479758924
```

Do not proceed if the identity, account purpose, region, permission source, or budget ownership is unclear.

## Bucket controls

The module configures:

- Bucket versioning for recovery.
- Explicit SSE-S3 (`AES256`) default encryption.
- Bucket-owner-enforced ownership; ACLs are disabled.
- All four S3 public-access-block settings.
- Bucket policy denial for non-TLS requests.
- `force_destroy = false`.
- `prevent_destroy = true`.
- Deterministic account/region-bound naming.

SSE-S3 avoids a KMS key and its policy/cost complexity for the lab. Production data-classification requirements may require a customer-managed KMS key, key rotation, cross-account key policy, and additional backend KMS permissions.

## Native lockfile permissions

Current Terraform S3 backend documentation deprecates DynamoDB locking. This lab uses:

```hcl
use_lockfile = true
```

The lock object is `<state-key>.tflock`. Both plan and apply need `GetObject`, `PutObject`, and `DeleteObject` on that exact lock object because they must acquire and release it.

The generated **plan policy** grants:

- `ListBucket` constrained to the exact state and lock prefixes.
- `GetObject` on the exact state object.
- `GetObject`, `PutObject`, `DeleteObject` on the exact lock object.

The generated **apply policy** adds `PutObject` on the exact state object. It intentionally does not grant `DeleteObject` on state.

The module outputs policy JSON but does not create or attach IAM roles. This prevents the lab from guessing organizational trust policies. In a real pipeline, attach the policy to a short-lived OIDC-assumed role with a tightly scoped trust relationship.

## Credential handling

- Do not put access keys, secret keys, session tokens, or role credentials in `.tf`, `.tfvars`, `backend.hcl`, or `-backend-config` arguments.
- Use AWS IAM Identity Center, instance roles, or CI OIDC federation.
- Backend credentials can be persisted in `.terraform/` and plan files if supplied as backend values; use standard credential mechanisms instead.
- `backend.hcl` in this lab contains only bucket, key, region, encryption, and lock settings, but it is generated and ignored to avoid accidental environment coupling.

## Bootstrap state

The bootstrap itself starts with local state because the bucket does not exist yet. That local bootstrap state is sensitive and must be protected. For this temporary lab it remains local until cleanup. In a real platform, bootstrap state belongs in separately administered durable storage, not on an engineer's laptop and not casually inside the bucket it must destroy.

## Restore authorization

State restore is a write to the backend and can roll infrastructure knowledge backward. `restore-state-version.sh` therefore:

- Requires an exact version ID.
- Requires exact `CONFIRM_STATE_RESTORE` text.
- Refuses while the `.tflock` object exists.
- Downloads to a mode-600 temporary file in a mode-700 directory.
- Validates the state with `terraform show -json`.
- Uploads historical content as a **new encrypted version**, preserving later versions.

After restoration, run `terraform plan`; never immediately apply assumptions from an old state.

## Logging and monitoring gaps

The lab does not create CloudTrail data-event logging, access-log destinations, alarms, IAM roles, KMS, or cross-account backups. Production backends should consider those controls according to sensitivity and compliance requirements.
