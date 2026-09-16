# Terraform Implementation Standards and Definition of Done

Use these standards for the roadmap and scenario catalog. Adapt them through documented architecture decisions; do not copy controls that do not fit the workload.

## 1. Architecture and ownership

Before implementation, record:

- Business/workload purpose, owner, support channel, data classification, criticality, and expected lifetime.
- Diagram, request/data flows, trust boundaries, AWS accounts/regions/AZs, and external dependencies.
- Availability, performance, RTO, and RPO targets derived from workload needs—not generic internet numbers.
- Estimated cost and major cost drivers; sandbox cleanup/TTL.
- Module boundaries, deployment roots, state boundaries, and why each boundary exists.
- Change, rollback/forward-fix, backup/restore, incident, and decommission paths.
- ADRs for meaningful choices such as ECS versus EKS, NAT versus endpoints, or backup versus active/active.

## 2. Code structure

### Reusable child module

```text
module-name/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── tests/
│   ├── defaults.tftest.hcl
│   ├── validation.tftest.hcl
│   └── integration.tftest.hcl
└── examples/
    ├── minimal/
    └── complete/
```

- The root `.tf` files are required by Terraform; the named split is a recommended convention.
- Use lowercase snake_case for resource labels and variables; use names that express purpose.
- Group related resources into readable files; Terraform loads all `.tf` files in a directory as one module.
- Child modules declare `required_providers` and their minimum compatible provider features, but never define provider configurations.
- Root/deployment modules own backend and provider configuration, aliases, default tags, and environment values.
- Prefer one level of child modules. Pass VPC IDs, subnets, security groups, role ARNs, endpoints, and other dependencies into modules.
- Avoid `depends_on` when a normal expression reference can express the actual dependency.
- Prefer `for_each` with meaningful stable keys for independently identified instances. Use `count` for truly index-like identical instances or a simple optional singleton.
- Do not use provisioners unless no provider/API-native solution exists; document idempotency, failure, secrets, and removal plan if one is unavoidable.

## 3. Input and output contracts

Every variable and output has a description. Variables use explicit types. Add validation for contract rules known at plan time.

```hcl
variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage, or prod."
  }
}
```

- Use objects to model cohesive contracts, but avoid one enormous untyped `any` configuration.
- Safe defaults should represent the common secure behavior. A required business decision should remain required.
- Define and test null/empty behavior. Avoid flags whose interactions create an untestable state space.
- Mark values `sensitive` to reduce display, while remembering sensitive values still exist in state and plans.
- Never output secret plaintext. Output a secret ARN/name if the consumer needs a reference.
- Outputs represent useful integration points and guarantees. Do not mirror every provider attribute.
- Use preconditions/postconditions/checks for important assumptions that types cannot express, with actionable error messages.

## 4. Version and dependency policy

- Use an approved stable Terraform release. This guide was checked with documentation for v1.16.x; v1.17.x was beta on 2026-09-16.
- Root modules constrain Terraform and provider versions to a tested range and commit `.terraform.lock.hcl`.
- Reusable child modules declare the minimum provider version required by their features; consumers select the compatible version.
- Registry modules use an explicit version constraint. Git module sources use a reviewed immutable tag or commit; commit pinning is strongest against tag movement.
- CI actions and reusable workflows are pinned according to supply-chain policy, preferably immutable commit SHAs.
- Automated update tools may open PRs, but do not automatically apply dependency upgrades to production.
- Read upgrade guides, inspect lockfile changes, run tests, apply in sandbox/dev, then promote.
- Module releases use semantic versioning: patch for compatible fixes, minor for compatible features, major for contract-breaking change. Publish release notes and migration steps.

## 5. State and backend standard

For AWS-hosted open-source Terraform state, use an S3 backend designed as administrative infrastructure:

- Bucket versioning enabled; encryption appropriate to policy; public access blocked.
- `use_lockfile = true` on current supported Terraform. DynamoDB locking is deprecated in current HashiCorp docs and should not be introduced for new designs unless compatibility is explicitly required.
- Least-privilege object-prefix access for state and `.tflock`; read access is sensitive access.
- Credentials supplied through standard AWS credential mechanisms/OIDC, not hardcoded backend arguments.
- Separate state by lifecycle, owner, privilege, blast radius, account, and region as appropriate.
- One mutation at a time per state; CI concurrency and backend locking both enforced.
- Backend bootstrap has a documented recovery path and is not casually destroyed with workloads.
- State version recovery is tested in a disposable environment.
- State sharing is minimized. Prefer provider data sources, well-governed parameter/catalog publication, or narrow output contracts. Remember `terraform_remote_state` readers need access to the underlying state snapshot even though only root outputs are returned in configuration.

Never:

- Commit or manually edit state.
- Copy state between environments as a cloning mechanism.
- Run routine production apply from arbitrary laptops.
- Force-unlock before verifying the original process is dead.
- Use `-target` as a normal delivery strategy; reserve it for exceptional recovery with review.

## 6. Security baseline

- No static long-lived AWS keys in CI. Use OIDC federation and short-lived role sessions.
- GitHub AWS trust policies validate `aud` and tightly scope `sub` to approved repository/branch or protected environment. Grant workflow `id-token: write` only where needed.
- Separate plan/read and apply/write capabilities where practical. Restrict production roles and session duration.
- Prevent untrusted fork/PR code from receiving cloud credentials or secrets.
- Encrypt data at rest and in transit according to classification; manage KMS key policies explicitly.
- Private application/data tiers by default; no public database; no unrestricted management ports.
- Use workload roles instead of credentials in user data, images, environment files, or Terraform variables.
- Store application secrets in an approved secret manager and test rotation.
- Enable and protect audit logs. Make deployment activity traceable to identity, repository, commit, and run.
- Scan HCL and plan representation where appropriate. A suppression requires rationale, owner, scope, and expiration.
- Review public modules/provider/action ownership, maintenance, license, source, release history, and transitive behavior before adoption.

## 7. Test pyramid

### Fast checks on every change

1. `terraform fmt -check -recursive`
2. Initialize safely for validation as required.
3. `terraform validate`
4. TFLint or an equivalent lint policy.
5. IaC security/misconfiguration scan.
6. Documentation freshness check.
7. Native plan/mocked tests.

### Native Terraform tests

`terraform test` is available from Terraform v1.6. By default, a test run uses `apply` and creates real infrastructure. Use `command = plan` or mock providers when real creation is not needed. Isolate and budget integration tests, and verify cleanup.

Test at least:

- Default/minimal contract and complete example.
- Invalid inputs and expected failures.
- Optional feature branches.
- Resource key/address stability.
- Security properties and important outputs.
- Upgrade compatibility for supported previous release(s).

### Integration and system checks

Use a small number of real, high-value tests:

- Reachability and denial paths.
- TLS/DNS and health checks.
- Workload identity and least privilege.
- Backup restore, queue redrive, deployment rollback, failover where relevant.
- Apply then no-op plan.
- Destroy/cleanup, except intentionally retained/protected data where a dedicated teardown procedure applies.

Local emulators and mocks improve speed but cannot prove AWS IAM, eventual consistency, quotas, or service integration. Keep at least one real test for critical patterns.

## 8. CI/CD gates

### Pull request

- Format, validate, lint, tests, security scan, and documentation checks.
- Plan only for trusted code with appropriately scoped read permissions.
- Plan is associated with commit SHA and displayed in reviewable form.
- Policy and cost-delta checks run on the plan when adopted.
- Required code owners review sensitive modules/roots.

### Apply

- Triggered only from an approved branch/release and protected environment.
- Uses short-lived identity and one state-specific concurrency group.
- Requires production approval independent of the author where policy demands.
- Applies the reviewed saved plan when still valid and secure, or generates a fresh plan and requires policy-consistent review. Never assume an old plan remains safe after state, credentials, or external dependencies change.
- Runs post-apply health checks and records evidence.
- Saved plans receive encryption/access control and short retention because they can contain sensitive data.

A pipeline is not safe merely because it is automated. IAM scope, event choice, untrusted code handling, action pinning, runner security, approvals, and state concurrency matter.

## 9. Observability and operations

Each production module/root should address where relevant:

- Logs, encryption, retention, access, and centralization.
- Metrics for availability, latency, errors, saturation/capacity, and business symptoms.
- Actionable alarms with owner, severity, and runbook link; test notifications.
- Deployment and configuration change events correlated with service signals.
- Tracing/correlation IDs across tiers when useful.
- Backup scope, schedule, retention, copy/immutability needs, and successful restore test.
- Quotas, certificate expiration, secret rotation, maintenance, scaling limits, and dependency health.
- Drift schedule, alert routing, emergency-change reconciliation, and exception process.
- Dashboards are diagnostic tools, not substitutes for alarms and runbooks.

## 10. Cost and sustainability

- Record expected monthly range and the assumptions behind it before apply.
- Identify hourly fixed-cost resources and data-transfer/NAT/log ingestion drivers.
- Use tags for owner, system, environment, cost center, data class, and managed-by where policy permits.
- Set sandbox TTL and cleanup automation. Verify snapshots, elastic IPs, NAT gateways, log groups, and other retained resources after destroy.
- Use cost estimation as decision support, not an exact bill prediction.
- Right-size from measurements; use autoscaling and lifecycle policies; avoid unnecessary always-on nonproduction replicas.
- Review architecture for utilization, managed-service overhead, and data movement as part of AWS cost optimization and sustainability pillars.

## 11. Change and failure runbooks

Maintain tested procedures for:

- Failed or interrupted apply and partial creation.
- Lock contention and verified stale lock.
- State version recovery and backend access loss.
- Drift and approved emergency changes.
- Resource import and ownership handoff.
- Address/module/state refactoring.
- Terraform, provider, and module upgrades.
- Secret/key/certificate rotation and compromise.
- Backup restore and regional failover/failback.
- Accidental deletion and destructive plan rejection.
- Quota exhaustion/provider API outage.
- Service and account decommissioning.

During an incident: stop competing mutations, preserve logs/state versions, identify remote reality and state ownership, make the smallest reviewed correction, converge with a normal plan/apply, validate service health, and record follow-up. Do not “fix” uncertainty by deleting state.

## 12. Module review checklist

- [ ] Purpose and non-goals are clear.
- [ ] Boundary is cohesive and raises abstraction.
- [ ] Inputs/outputs are typed, described, minimal, and tested.
- [ ] No provider configuration exists in the reusable child.
- [ ] Dependencies are injected and module tree stays shallow.
- [ ] Secure defaults, logging, encryption, tagging, and deletion behavior are explicit.
- [ ] Minimal/complete examples validate.
- [ ] Native tests cover success/failure and optional paths.
- [ ] Real integration coverage exists for critical AWS behavior.
- [ ] No secret/state/plan is committed or exposed.
- [ ] Version constraints and lockfile usage follow root versus child policy.
- [ ] Upgrade impact and moved blocks are considered.
- [ ] README, diagram, cost, operations, and ownership are current.
- [ ] CI quality gates pass.

## 13. Deployment definition of done

A scenario or capstone is done only when:

1. Requirements, targets, diagram, state/module boundaries, threat/cost model, and owner are recorded.
2. Code passes format, validate, lint, tests, scans, and policy gates.
3. Plan is reviewed and contains no unexplained replacement or sensitive disclosure.
4. Apply succeeds through the intended identity and pipeline.
5. Functional, security, reachability, observability, and resilience criteria are demonstrated.
6. A second plan is no-op, or any expected perpetual difference is justified and fixed where possible.
7. Backup/rollback/forward-fix and relevant failure drill are tested.
8. Evidence is retained according to policy.
9. Documentation and runbooks let another engineer operate it.
10. Lab cleanup is verified, or production ownership/retention is formally handed over.

## 14. Production-readiness review questions

- What happens if this apply stops halfway?
- What can this pipeline role destroy or exfiltrate?
- Can a pull request from an untrusted source obtain credentials?
- Who can read state and saved plans?
- Which resources are replaced by a routine input or provider upgrade?
- What happens when one AZ, region, dependency, or AWS API is unavailable?
- Can data be restored, and when was restore last tested?
- How are secrets/certificates rotated before expiry or compromise?
- Which alarms are actionable, and who receives them?
- What is the largest cost surprise this design can create?
- How is drift reconciled after an emergency change?
- How is ownership transferred or the system safely decommissioned?

If these questions cannot be answered with evidence, the infrastructure is not yet production-ready.
