# Terraform Modules on AWS: Production Learning and Implementation Roadmap

> Research-checked on **2026-09-16** against current HashiCorp, AWS, and GitHub documentation. HashiCorp documentation currently labels Terraform **v1.16.x** as latest stable and v1.17.x as beta. Recheck versions before implementation.

This is an implementation-first path from Terraform basics to production Infrastructure as Code (IaC). It is AWS-focused because real depth is more useful than shallow multi-cloud coverage. The design practices—module contracts, state boundaries, CI/CD, testing, policy, and operations—transfer to other providers.

This guide cannot enumerate every architecture any company could invent. It provides a broad, industry-aligned catalog of recurring implementation, delivery, migration, and incident scenarios. See [SCENARIOS.md](SCENARIOS.md) for the catalog and [IMPLEMENTATION_STANDARDS.md](IMPLEMENTATION_STANDARDS.md) for the definition of done.

## Hands-on implementation

- [Learning progress](PROGRESS.md)
- [Lab 01 — Terraform foundations without cloud resources](labs/01-foundations/README.md)
- [Lab 02 — Reusable modules and flat composition](labs/02-module-composition/README.md)

## 1. Outcomes

By completing the roadmap, you should be able to:

- Translate an architecture diagram and non-functional requirements into state boundaries, root modules, and reusable child modules.
- Build secure AWS foundations and connect public entry points, private application backends, databases, queues, and observability systems.
- Design explicit module contracts using typed inputs, validation, outputs, preconditions, postconditions, and tests.
- Bootstrap and operate an S3 remote backend with versioning and native lockfiles.
- Deliver reviewed plans and controlled applies with short-lived GitHub OIDC credentials.
- Test, scan, release, upgrade, import, refactor, recover, and decommission infrastructure safely.
- Apply the six AWS Well-Architected pillars: operational excellence, security, reliability, performance efficiency, cost optimization, and sustainability.

## 2. Non-negotiable safety rules

1. Use a dedicated sandbox AWS account, not a production account.
2. Configure AWS Budgets and billing alerts before creating chargeable resources.
3. Start with low-cost resources and destroy labs promptly. NAT gateways, load balancers, managed databases, EKS, Network Firewall, Transit Gateway, and cross-region traffic can incur ongoing cost.
4. Never commit credentials, private keys, secrets, `.tfstate`, saved plan files, or secret-bearing `.tfvars`.
5. Prefer short-lived AWS IAM Identity Center credentials locally and OIDC federation in CI.
6. Review every plan. Never use automatic `-auto-approve` against important environments without an appropriately controlled pipeline.
7. Back up and lock state before migration or repair. Never hand-edit JSON state.
8. Use `prevent_destroy` only as an additional guardrail, not a substitute for IAM, backups, approvals, and runbooks.
9. Test failure and recovery in disposable environments first.
10. Treat generated code, public modules, providers, CI actions, and container images as supply-chain dependencies that require review and pinned versions.

## 3. Prerequisites

- Git, GitHub or an equivalent VCS platform, basic Linux shell usage, JSON/YAML, networking fundamentals, and basic AWS knowledge.
- Terraform stable release approved by your team; this guide was checked against v1.16.x.
- AWS CLI with a sandbox profile or IAM Identity Center session.
- Optional quality tools: `tflint`, Trivy or Checkov, `terraform-docs`, `pre-commit`, OPA/Conftest, and Infracost. These are not Terraform requirements.
- An editor with HCL support.

Before AWS work, be able to explain CIDR ranges, subnets, routes, DNS, TLS, ports, security groups, IAM roles/policies, availability zones, RTO, and RPO.

## 4. Mental model: four layers

1. **Resource** — one provider object such as `aws_vpc` or `aws_ecs_service`.
2. **Reusable child module** — a cohesive capability with a stable contract, such as a VPC, ALB, service, queue, or database. It declares provider requirements but does not configure providers.
3. **Root module / deployment unit** — composes child modules for one system and owns provider/backend configuration and one state boundary.
4. **Platform/environment** — multiple independently delivered root modules across accounts, regions, and lifecycle boundaries.

Prefer a flat root that wires modules together:

```hcl
module "network" {
  source = "../../modules/network"
  name   = local.name
  cidr   = var.vpc_cidr
}

module "backend" {
  source = "../../modules/backend_service"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  alb_listener_arn   = module.edge.https_listener_arn
  database_endpoint  = module.database.endpoint
}
```

Dependencies are passed in; the backend module should not silently create its own VPC and database. HashiCorp strongly recommends a mostly flat, one-level module tree and dependency inversion.

## 5. Recommended repository shape

Start as a monorepo while learning; split mature, independently released modules into their own repositories only when ownership and release cadence justify it.

```text
terraform_module/
├── README.md
├── SCENARIOS.md
├── IMPLEMENTATION_STANDARDS.md
├── modules/
│   ├── network/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── tests/
│   │   └── examples/
│   ├── edge/
│   ├── backend_service/
│   └── database/
├── live/
│   ├── bootstrap-state/
│   ├── dev/us-east-1/app/
│   ├── stage/us-east-1/app/
│   └── prod/us-east-1/app/
├── policies/
├── scripts/
└── .github/workflows/
```

Each deployable root has a separate backend key and usually its own state. Do not create one state containing the entire organization. Split by lifecycle, ownership, privilege, blast radius, and rate of change—not merely by AWS service.

## 6. Module contract standard

A reusable module should normally include:

- `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`.
- README with purpose, architecture, usage, requirements, security decisions, upgrade notes, and examples.
- Typed variables; descriptions; sane defaults only when there is a safe general default; nullable behavior documented.
- Variable validation and resource/output preconditions where they make assumptions explicit.
- Useful outputs representing integration points, not every resource attribute.
- `required_providers`; no `provider` block in a reusable child module.
- Tags, naming, encryption, logging, and deletion behavior defined consistently.
- Plan-based tests, mocked-provider tests where appropriate, and a small number of real integration tests.
- A changelog and semantic release policy once consumers depend on it.

Do not build thin wrappers around every resource, giant modules with hundreds of unrelated switches, deeply nested module trees, or modules that discover/create dependencies unpredictably.

## 7. Staged curriculum

Effort is intentionally expressed as stages rather than promises about weeks. Repeat each stage until its exit gate passes.

### Stage 0 — Safety, requirements, and architecture

**Learn:** IaC benefits and limits, declarative execution, AWS shared responsibility, Well-Architected pillars, cost awareness, blast radius, RTO/RPO, and environment strategy.

**Build:** sandbox account checklist, budget alert, tagging convention, architecture decision record (ADR), threat model, and cleanup runbook.

**Exit gate:** you can state who owns each resource, where state lives, what failure is acceptable, how cost is bounded, and how the lab is destroyed.

### Stage 1 — HCL and Terraform lifecycle

**Learn:** blocks, expressions, types, variables, locals, outputs, data sources, resource references, unknown values, sensitivity, `for_each`, `count`, dynamic blocks, lifecycle, `depends_on`, and CLI flow.

**Build:** local-file/random exercises, then a tagged and encrypted S3 bucket in a sandbox.

**Practice:** `init`, `fmt`, `validate`, `plan`, saved plans, `apply`, `show`, `output`, `state list`, `destroy`.

**Exit gate:** the second plan is no-op; changing one input produces an explainable diff; no state or secrets are committed.

### Stage 2 — Reusable modules and contracts

**Learn:** child versus root modules, module sources, typed objects, optional attributes, validation, pre/postconditions, outputs, provider inheritance/aliases, composition, and semantic versioning.

**Build:** modules for naming/tags (only if it raises abstraction), S3 data storage, security groups, and a basic EC2 service. Compose them in a root module.

**Tests:** valid defaults, invalid input, expected outputs, conditional resources, `for_each` address stability, and provider alias wiring.

**Exit gate:** another root can use the module without editing it; its README and example are sufficient; tests pass; an input removal is correctly recognized as breaking.

### Stage 3 — Remote backend and state operations

**Learn:** state sensitivity, locking, backend initialization, partial backend configuration, state isolation, lineage, refresh, drift, imports, and recovery.

**Build:** a separate `bootstrap-state` root that creates an S3 bucket with versioning, encryption, public-access blocking, restrictive IAM, logging/monitoring as required, and lifecycle protection. Migrate a lab from local state to S3.

Use current S3-native locking:

```hcl
terraform {
  backend "s3" {
    bucket       = "REPLACE_DURING_INIT"
    key          = "dev/us-east-1/app/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

Backend blocks cannot use normal input variables. Supply environment-specific backend values through approved partial configuration and do not place credentials in backend arguments. Current HashiCorp docs deprecate DynamoDB-based locking; use it only for a documented migration compatibility need.

**Drills:** concurrent plan/apply, stale lock investigation, version recovery, accidental local-state creation, backend migration, and least-privilege denial.

**Exit gate:** lock contention is demonstrated; only intended roles can read/write state; state can be restored in a disposable exercise; the runbook warns that state and plans may contain secrets.

### Stage 4 — Networking and connectivity

**Learn:** multi-AZ VPCs, public/private/isolated subnets, route tables, internet/NAT gateways, VPC endpoints, DNS, NACLs versus security groups, IPv6, flow logs, and connectivity testing.

**Build modules:** `network`, `vpc_endpoints`, `flow_logs`, `route53_zone`, and narrowly scoped security-group rules.

**Exercises:**
- Public ALB can reach an application target on only its listener/target port.
- Application can reach a database on only the database port.
- Database has no route from the internet and no public address.
- Private workloads reach AWS APIs via selected VPC endpoints.
- Operators connect through Systems Manager Session Manager rather than open SSH.

**Exit gate:** Reachability Analyzer or controlled probes prove intended paths and denied paths; VPC Flow Logs are queryable; no `0.0.0.0/0` ingress exists without explicit justification.

### Stage 5 — Connect frontend, backend, and database

A common industry pattern is:

```text
Users → Route 53 → CloudFront/WAF (optional) → public ALB
       → private backend service (EC2 ASG, ECS, or EKS)
       → isolated RDS/Aurora
       → SQS/SNS/EventBridge for asynchronous work
       → CloudWatch logs, metrics, alarms, and traces
```

**Recommended module boundaries:**

- `network`: VPC, subnets, routing, optional endpoints.
- `edge`: ACM certificate, ALB/CloudFront, listeners, WAF association.
- `backend_service`: compute, target attachment, autoscaling, task/instance role.
- `database`: subnet/parameter groups, encrypted database, backup policy.
- `service_security`: security-group relationships expressed by group IDs.
- `observability`: log groups, alarms, dashboards, notifications.

**Important connection rules:**

- Reference security groups instead of broad CIDRs where possible.
- Pass `module.database.endpoint` and secret ARN to the service; do not output the password.
- Let the workload retrieve credentials from Secrets Manager/Parameter Store using its IAM role.
- Use health checks that test application readiness, not just an open port.
- Keep schema migration ownership explicit; Terraform generally provisions database infrastructure, not application schema lifecycle.

**Exit gate:** TLS works; only the load balancer can reach the backend; only the backend can reach the database; secret rotation does not require committing a value; logs and alarms identify failed health checks; a second plan is no-op.

### Stage 6 — Compute and application delivery patterns

Implement comparable services to understand tradeoffs:

1. EC2 launch template + Auto Scaling Group + ALB.
2. ECS Fargate + ECR + ALB + autoscaling.
3. Lambda + API Gateway + IAM + logs.
4. EKS managed cluster/node groups only after mastering VPC, IAM, containers, and state boundaries.
5. Static S3 origin + CloudFront OAC + Route 53 + ACM.

Add immutable artifacts, deployment health, rollback, autoscaling, graceful termination, and capacity/quota considerations. Terraform provisions platform infrastructure; application pipelines should publish versioned artifacts and deliberately update image/AMI/function versions.

**Exit gate:** deployment and rollback are demonstrated; an unhealthy release does not silently remain active; scaling and logs are observable; infrastructure and application release responsibilities are documented.

### Stage 7 — Data, storage, and messaging

**Build:** S3 lifecycle/replication, EBS/EFS where justified, RDS/Aurora, DynamoDB, ElastiCache, SQS with DLQ, SNS, EventBridge, Step Functions, Kinesis, and a small Glue/Athena data-lake path.

**Learn:** encryption keys and policies, backup/PITR, maintenance windows, parameter groups, connection limits, retention, idempotency, retries, DLQ redrive, schema ownership, and destructive-change review.

**Exit gate:** backup and restore are tested, not merely configured; poison messages reach a DLQ; retention and deletion policies match data classification; alarms cover saturation and failure.

### Stage 8 — CI/CD and short-lived identity

**PR pipeline:** format → validate → lint → test (safe plan/mocks) → security scan → plan → cost/policy checks → review.

**Protected apply pipeline:** merge or release → fresh/saved reviewed plan according to policy → environment approval → apply once → post-apply checks → audit evidence.

Use GitHub OIDC rather than long-lived AWS keys. Trust policy conditions must restrict `aud` and especially `sub` to the expected repository, branch, or protected environment. Workflow permissions require `id-token: write`; use `aws-actions/configure-aws-credentials`. Pin actions to reviewed immutable commit SHAs where feasible.

Do not grant cloud credentials to untrusted pull-request code. Serialize applies per state. Protect plan artifacts because they can contain sensitive values.

**Exit gate:** a PR cannot apply; production requires approval; an unauthorized repo/branch cannot assume the AWS role; two applies cannot mutate one state concurrently; logs identify actor, commit, plan, and result.

### Stage 9 — Security, policy, observability, and cost

**Security:** least privilege, KMS, Secrets Manager, IAM Access Analyzer, CloudTrail, Config, GuardDuty/Security Hub where appropriate, WAF, private access, and dependency scanning.

**Policy:** start with module defaults and tests, then static analysis, then policy as code for organization-wide rules. OPA/Conftest is an OSS option; HCP Terraform/Sentinel is a commercial-integrated option. Avoid duplicate policies that disagree.

**Observability:** logs with retention/encryption, metrics, alarms, dashboards, traces, deployment events, state/backend access alerts, and actionable runbooks.

**Cost:** budgets, mandatory ownership/cost tags, estimate PR deltas, right-size, lifecycle/delete ephemeral resources, and document fixed-cost components.

**Exit gate:** deliberately insecure code is blocked; exceptions are time-bound and reviewed; a synthetic failure pages the expected route; the owner can explain major cost drivers.

### Stage 10 — Multi-account, multi-region, and resilience

**Learn/build:** AWS Organizations/OUs/SCPs, Control Tower integration boundaries, delegated administration, central logging/security accounts, cross-account assume-role, provider aliases, shared networking, Transit Gateway, private DNS, backup copies, and regional failover patterns.

Use separate accounts for stronger environment/security isolation. Keep bootstrap, organization, network, data, and application states separate. Avoid a single privileged pipeline role for every account.

Define workload-specific RTO/RPO before choosing backup/restore, pilot light, warm standby, or active/active. Terraform can provision both regions and routing controls; it does not by itself guarantee data consistency or application failover.

**Exit gate:** trust and permission boundaries are tested; regional dependencies are inventoried; failover and failback are rehearsed; DNS/data replication behavior is measured against declared targets.

### Stage 11 — Brownfield, refactoring, upgrades, and incidents

**Practice:** configuration-driven `import` blocks, generated configuration review, `moved` blocks, `removed` blocks, `terraform state mv` with backups, module decomposition, provider/Terraform upgrades, lockfile changes, drift triage, partial apply recovery, and safe decommissioning.

**Rules:**
- First make imported configuration match reality; require a no-change plan before modernization.
- Prefer declarative `moved` blocks for repeatable address migrations.
- Never respond to a failed apply by deleting state blindly.
- Upgrade one dimension at a time and read provider/module upgrade guides.
- Rollback usually means a forward code correction or application rollback; Terraform cannot universally reverse destructive cloud operations.

**Exit gate:** import produces no unintended changes; refactor produces no resource recreation; a failed apply is diagnosed from state and provider reality; upgrade and rollback evidence is recorded.

### Stage 12 — Platform engineering and module product ownership

**Build:** a versioned module catalog, golden root templates, reusable workflows, ownership metadata, compatibility matrix, examples, changelog, deprecation policy, scorecards, and self-service interface with quotas and guardrails.

Publish a module only when there are real consumers and an owner. Treat module interfaces as APIs. Use semantic versioning, release notes, contract tests, upgrade examples, and a supported-version policy. Registry options include the public Terraform Registry and commercial/private registry products; Git sources are also possible when pinned.

**Exit gate:** a consumer upgrades through a documented release without direct author help; a breaking change receives a major version; deprecated inputs have a migration path; ownership and support expectations are explicit.

## 8. Recommended implementation order

Use this order rather than attempting EKS or multi-region first:

1. S3 bucket configuration with local state.
2. First reusable storage module and tests.
3. S3 backend bootstrap and state migration.
4. Multi-AZ VPC and connectivity tests.
5. Private EC2 backend reached through an ALB.
6. Add RDS and secret retrieval.
7. Rebuild the service on ECS Fargate.
8. Build a Lambda/API Gateway variant.
9. Add queue/DLQ and event-driven worker.
10. Add CI plan workflow and GitHub OIDC.
11. Add scans, policy checks, approvals, drift detection, and cost review.
12. Separate dev/stage/prod accounts and roles.
13. Import and refactor a brownfield resource without recreation.
14. Run state, failed-apply, secret-rotation, and backup-restore drills.
15. Complete one capstone and publish selected modules.

## 9. Capstones

### Capstone A — Secure three-tier service

CloudFront/WAF (optional), Route 53/ACM, ALB, ECS/EC2 private service, RDS/Aurora isolated database, Secrets Manager, SQS/DLQ, CloudWatch, backup, CI/OIDC, policy, and cost controls.

### Capstone B — Event-driven serverless platform

API Gateway, Lambda, EventBridge, SQS/DLQ, Step Functions, DynamoDB, S3, observability, replay/redrive, reserved concurrency, and least-privilege roles.

### Capstone C — Container platform

ECS first or EKS for advanced study, private networking, workload identity, image registry/scanning, ingress, autoscaling, secrets, logs/traces, deployment rollback, and tenant/team boundaries.

### Capstone D — Multi-account landing and delivery platform

Organizations/OUs, baseline policies, centralized audit/security, account-specific deployment roles, OIDC pipelines, state isolation, shared networking, module registry, and policy exceptions workflow.

### Capstone E — Resilient regional workload

Two-region infrastructure, replicated data appropriate to the service, health-based routing/routing controls, backup, failover/failback automation, game-day evidence, and declared workload-specific RTO/RPO.

Every capstone must meet the definition of done in [IMPLEMENTATION_STANDARDS.md](IMPLEMENTATION_STANDARDS.md).

## 10. How to use the scenario catalog

For each scenario in [SCENARIOS.md](SCENARIOS.md):

1. Write requirements, diagram, threat model, cost estimate, and state/module boundaries.
2. Build a minimal version directly with resources to understand the provider.
3. Extract a module only after the boundary and repeated contract are clear.
4. Add tests and failure cases.
5. Deliver through CI.
6. Prove acceptance criteria and a no-op second plan.
7. Run cleanup and verify no billable leftovers.
8. Record an ADR describing tradeoffs and what you would change at larger scale.

## 11. Authoritative references

### Terraform

- Modules overview: https://developer.hashicorp.com/terraform/language/modules
- Standard module structure: https://developer.hashicorp.com/terraform/language/modules/develop/structure
- Module composition: https://developer.hashicorp.com/terraform/language/modules/develop/composition
- Providers within modules: https://developer.hashicorp.com/terraform/language/modules/develop/providers
- Module refactoring: https://developer.hashicorp.com/terraform/language/modules/develop/refactoring
- Module publishing: https://developer.hashicorp.com/terraform/registry/modules/publish
- Style guide: https://developer.hashicorp.com/terraform/language/style
- Tests: https://developer.hashicorp.com/terraform/language/tests
- Mock providers: https://developer.hashicorp.com/terraform/language/tests/mocking
- S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3
- State security: https://developer.hashicorp.com/terraform/language/state/sensitive-data
- Import: https://developer.hashicorp.com/terraform/language/import
- AWS provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

### AWS and delivery

- AWS Terraform provider best practices: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/introduction.html
- AWS Well-Architected pillars: https://docs.aws.amazon.com/wellarchitected/latest/framework/the-pillars-of-the-framework.html
- AWS Architecture Center: https://aws.amazon.com/architecture/
- AWS security best practices for IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GitHub OIDC for AWS: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws

### Optional ecosystem tools

- TFLint: https://github.com/terraform-linters/tflint
- Trivy IaC scanning: https://trivy.dev/latest/docs/scanner/misconfiguration/
- Checkov: https://www.checkov.io/
- terraform-docs: https://terraform-docs.io/
- pre-commit: https://pre-commit.com/
- OPA: https://www.openpolicyagent.org/docs/latest/terraform/
- Infracost: https://www.infracost.io/docs/
- Terratest: https://terratest.gruntwork.io/

Optional tools and commercial product capabilities change independently. Evaluate current licensing, security, supported versions, and pricing before adoption.
