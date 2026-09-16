# Terraform on AWS: Real-World Scenario Catalog

This catalog complements the [main roadmap](README.md). It is broad rather than literally exhaustive; organizations create additional domain-specific patterns. `B`, `I`, and `A` mean beginner, intermediate, and advanced.

## Universal evidence for every build

Unless a row overrides it, completion means: formatted and validated code; reviewed plan; successful apply in a sandbox; expected behavior tested; second plan reports no changes; state/secrets are protected; tags and observability exist where relevant; cleanup succeeds; and the README records assumptions, cost drivers, rollback/recovery, and ownership.

## A. Language, resource lifecycle, and module design

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| A01 | B | S3 bucket root: encryption, versioning, public-access block, ownership controls | Public access test is denied; uploaded object is encrypted. |
| A02 | B | Inputs/locals/outputs: naming and common tags | Invalid environment fails validation; outputs contain no secret. |
| A03 | B | Stable collections: resources with `for_each` keyed by name | Removing one key affects only that instance. |
| A04 | B | Optional resources: logs, alarms, or replica toggles | Both enabled and disabled paths pass plan tests. |
| A05 | B | Data sources: select account, region, AZs, and an approved AMI | Plan fails clearly when assumptions are unmet. |
| A06 | I | First reusable storage module with typed object input | A second root consumes it without module edits. |
| A07 | I | Contract validation: variable rules, preconditions, postconditions | Positive and expected-failure tests pass. |
| A08 | I | Flat composition: root connects network, service, and data modules | Graph/dependency changes are explainable; no module creates hidden dependencies. |
| A09 | I | Provider aliases: module operates in two regions/accounts | Each resource appears only in the intended target. |
| A10 | I | Module `for_each`: deploy one service module per map entry | Keys remain stable through addition/removal. |
| A11 | I | Native tests: `command = plan`, assertions, expected failures | Tests run without real AWS creation where not needed. |
| A12 | I | Mocked provider tests for computed values | Logic is tested without cloud credentials; mock limits are documented. |
| A13 | I | Real integration test in ephemeral account/namespace | Test creates, verifies, and destroys all resources. |
| A14 | I | Examples: minimal, complete, and upgrade example | Examples initialize and validate independently. |
| A15 | I | Documentation generation with `terraform-docs` | Generated contract matches module inputs/outputs. |
| A16 | A | Module release with semantic version and changelog | Consumer pins release and automated compatibility test passes. |
| A17 | A | Backward-compatible new input/default | Existing consumer plan remains no-op. |
| A18 | A | Intentional breaking contract change | Major version and migration instructions are published. |
| A19 | A | Replace giant conditional module with composable modules | Consumers select modules explicitly; test matrix shrinks. |
| A20 | A | Data-only “join existing network” module | Management and lookup modules expose compatible integration outputs. |

## B. Backend, state, collaboration, and drift

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| B01 | B | Local state lifecycle and `.gitignore` | Repository history contains no state/plan files. |
| B02 | I | `bootstrap-state` root creates dedicated S3 state bucket | Versioning, encryption, public-access block, and restricted IAM are verified. |
| B03 | I | Migrate local state to S3 backend | Resource addresses and no-op plan are unchanged after migration. |
| B04 | I | S3 native `use_lockfile` | A concurrent mutation waits/fails safely rather than racing. |
| B05 | I | Separate backend keys for dev/stage/prod | Each state lists only its environment resources. |
| B06 | I | Split network and app state by lifecycle | App obtains documented network integration values without write access to network state. |
| B07 | I | Backend partial configuration | No credentials or sensitive backend values are committed. |
| B08 | I | State IAM roles: read-plan versus write-apply | Plan role cannot mutate state; unauthorized role cannot read it. |
| B09 | I | State object version recovery drill | A disposable state version is restored and reconciles to no-op. |
| B10 | I | Stale lock investigation | Owner/process is verified before force-unlock; procedure is recorded. |
| B11 | I | Scheduled `plan -refresh-only` / drift workflow | Deliberate tag drift creates an alert with owner and remediation path. |
| B12 | I | Reconcile approved emergency console change | Code/state converge with reviewed evidence, not blind overwrite. |
| B13 | A | State decomposition from monolith into two roots | Backups exist; moved/import procedure causes no recreation. |
| B14 | A | Cross-account administrative state architecture | Backend and provider assume-role paths have separate least privileges. |
| B15 | A | State disaster: accidental key deletion/corruption simulation | Recovery meets the team’s documented target in a sandbox. |
| B16 | A | Backend region/service disruption tabletop | Runbook identifies what can and cannot safely proceed. |

## C. AWS networking and service connectivity

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| C01 | B | Single VPC with public/private subnets across two AZs | Route tables and subnet classifications match diagram. |
| C02 | B | Internet gateway and public route | Only intended public test resource has internet path. |
| C03 | I | NAT per AZ versus centralized NAT decision | Failure/cost tradeoff is documented and routing tests pass. |
| C04 | I | Isolated database subnets | No internet route/public address; only app security group reaches DB port. |
| C05 | I | Security groups as module contracts | ALB→app and app→DB paths pass; direct user→app/DB paths fail. |
| C06 | I | VPC Flow Logs module | Allowed and rejected test flows are queryable with retention set. |
| C07 | I | Gateway endpoints for S3/DynamoDB | Private workload reaches service without NAT path. |
| C08 | I | Interface endpoints for selected AWS APIs | Private DNS resolution and least-privilege endpoint policy are tested. |
| C09 | I | Systems Manager Session Manager access | Instance is managed without inbound SSH or stored private key. |
| C10 | I | Route 53 private hosted zone/service discovery | Private clients resolve; public resolver does not expose private record. |
| C11 | I | VPC peering with non-overlapping CIDRs | Bidirectional intended routes work; transitive routing assumption is rejected. |
| C12 | A | Transit Gateway hub-and-spoke | Association/propagation matrix permits only intended VPC flows. |
| C13 | A | Inspection VPC with Network Firewall | Selected egress crosses inspection and blocked test domain/flow is logged. |
| C14 | A | Shared VPC/subnets through AWS RAM | Consumer account deploys only into authorized shared subnets. |
| C15 | A | Site-to-Site VPN | Redundant tunnels/routes and simulated tunnel failure are observed. |
| C16 | A | Direct Connect model/tabletop | VIF, BGP, encryption, and backup-path requirements are documented. |
| C17 | A | Dual-stack IPv4/IPv6 VPC | Egress/ingress controls and DNS behavior are tested for both families. |
| C18 | A | VPC IPAM allocation | Overlapping CIDR request is prevented; allocations are traceable. |
| C19 | A | Reachability Analyzer automation | Expected reachable/unreachable paths are assertions or deployment checks. |
| C20 | A | PrivateLink provider/consumer service | Consumer reaches service privately without broad network routing. |

## D. Edge, compute, and application platforms

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| D01 | B | EC2 module: launch template, IAM role, encrypted root disk | Instance passes SSM and metadata-v2 checks; no public SSH. |
| D02 | I | ALB module with HTTP→HTTPS and ACM | Valid TLS; HTTP redirects; unhealthy target is removed. |
| D03 | I | EC2 Auto Scaling Group backend | Scale-out/in and graceful termination are observed. |
| D04 | I | Complete frontend→ALB→private backend connection | Only ALB security group reaches backend target port. |
| D05 | I | Static S3 origin with CloudFront OAC | Direct S3 read is denied; CloudFront serves content. |
| D06 | I | Route 53 alias and certificate DNS validation | Domain resolves and certificate renewal ownership is documented. |
| D07 | I | AWS WAF association and managed/custom rules | Harmless test rule blocks matching request and emits metrics/logs. |
| D08 | I | ECR repository with scan/lifecycle policy | Vulnerable image finding is visible; stale untagged image expires. |
| D09 | I | ECS cluster and Fargate service module | Desired count remains healthy; task uses role, not static keys. |
| D10 | I | ECS service behind ALB with autoscaling | Load test triggers declared policy and alarms remain useful. |
| D11 | A | ECS blue/green or canary delivery integration | Failed release rolls traffic back under documented conditions. |
| D12 | I | Lambda module with logs, role, versions/alias | Invocation works with least privilege and bounded retention. |
| D13 | I | API Gateway HTTP API→Lambda backend | Auth/throttling/error responses and trace correlation are tested. |
| D14 | A | Lambda provisioned/reserved concurrency decision | Throttle behavior and downstream protection are measured. |
| D15 | A | EKS cluster foundation | Private/public endpoint decision, control-plane logs, encryption, and access are verified. |
| D16 | A | EKS managed node groups/Karpenter boundary | Workload schedules and node disruption respects availability constraints. |
| D17 | A | EKS workload identity (IRSA or current approved mechanism) | Pod accesses only intended AWS API without static credentials. |
| D18 | A | Ingress/load balancer controller add-on lifecycle | Controller upgrade and rollback are rehearsed separately from app. |
| D19 | A | Multi-tenant service modules | Per-service roles, logs, quotas, and network boundaries are demonstrated. |
| D20 | A | AMI/image pipeline handoff | Terraform consumes immutable artifact ID; build pipeline owns artifact creation. |

## E. Databases, storage, messaging, and analytics

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| E01 | I | RDS PostgreSQL/MySQL module in isolated subnets | Encrypted connection succeeds only from app; backup and deletion policy are explicit. |
| E02 | I | Backend retrieves DB secret using IAM role | No password appears in repository/output; rotation path is tested. |
| E03 | I | RDS snapshot restore drill | Restored database passes application smoke test. |
| E04 | A | Aurora cluster and reader endpoint | Writer/reader behavior and failover are observed against declared targets. |
| E05 | A | RDS Proxy for bursty/serverless clients | Connection behavior is measured and secret integration works. |
| E06 | I | DynamoDB table with PITR and capacity mode decision | Read/write test, recovery setting, encryption, and alarm checks pass. |
| E07 | A | DynamoDB global table | Cross-region replication and conflict/application assumptions are tested. |
| E08 | I | ElastiCache/Redis private cache | Only app can connect; failover/eviction metrics are visible. |
| E09 | I | EFS shared storage | Mount targets span intended AZs and only workload SG can mount. |
| E10 | I | S3 lifecycle/archive policy | Test object transitions/expires according to safe lab policy. |
| E11 | A | S3 cross-region replication | Replication status, KMS permissions, delete-marker behavior, and cost are documented. |
| E12 | B | SQS queue + DLQ module | Poison message reaches DLQ after configured receives. |
| E13 | I | SNS fan-out to multiple SQS queues | Each subscriber receives once-or-more and handles duplicates. |
| E14 | I | EventBridge event bus/rules/archive | Matching, nonmatching, archive, and replay behavior are verified. |
| E15 | A | Step Functions workflow with retries/catch | Injected task failure follows retry/catch and emits an alarm. |
| E16 | A | Kinesis stream/Firehose path | Measured sample load reaches destination with failure backup configured. |
| E17 | A | MSK cluster and client authentication | Encryption/authentication and broker failure behavior are tested. |
| E18 | I | S3 data lake zones + Glue Catalog + Athena | Query works with access boundaries and Athena result controls. |
| E19 | A | Lake Formation permissions | Analyst and producer roles see only authorized databases/tables. |
| E20 | A | OpenSearch domain | Private access, encryption, snapshots, logs, and capacity alarms are verified. |

## F. Identity, secrets, security, compliance, and audit

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| F01 | B | Least-privilege workload IAM role | Required call succeeds; unrelated service/action is denied. |
| F02 | I | Customer-managed KMS key module | Key policy permits intended service/roles and denies unapproved principal. |
| F03 | I | Secrets Manager secret and rotation integration | Rotation succeeds without code/state containing plaintext. |
| F04 | I | SSM Parameter Store configuration path | Workload reads allowed path only; SecureString uses controlled KMS key. |
| F05 | I | CloudTrail organization/account trail | Management event appears in protected central destination. |
| F06 | I | AWS Config recorder/rules | Deliberate noncompliance is detected and ownership is notified. |
| F07 | A | Config conformance pack and exception process | Exception has owner, rationale, scope, and expiration. |
| F08 | I | GuardDuty/Security Hub enablement and aggregation | Test/sample finding reaches central workflow. |
| F09 | I | IAM Access Analyzer | External-access finding is produced, reviewed, and archived/remediated with reason. |
| F10 | A | Permission boundaries for deployment roles | Pipeline cannot grant permissions beyond boundary. |
| F11 | A | SCP guardrails | Member-account admin cannot perform explicitly denied risky action. |
| F12 | A | Central log archive account | Workload role cannot alter retained audit logs. |
| F13 | A | Macie/classification workflow for S3 | Sample classification finding routes to owner without exposing data. |
| F14 | I | Static IaC security scanner in CI | Known insecure fixture fails; suppression requires documented review. |
| F15 | A | Plan policy as code | Public storage/unapproved region/required tags policy blocks fixture. |
| F16 | A | CI supply-chain hardening | Actions/modules/providers are pinned and update process verifies provenance/release notes. |

## G. Observability, reliability, and cost control

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| G01 | B | CloudWatch log group module | Retention and encryption are set; logs arrive with owner tags. |
| G02 | I | Service metrics/alarms/dashboard | Synthetic failure crosses threshold and notification links to runbook. |
| G03 | I | Composite alarm to reduce noise | Component signals combine as designed in a controlled test. |
| G04 | I | Distributed tracing with X-Ray/OpenTelemetry | One request is correlated across entry and backend components. |
| G05 | I | Central cross-account log subscriptions | Central team queries member logs; member cannot alter archive. |
| G06 | I | Synthetics/canary health check | User-path failure is detected independently of service metrics. |
| G07 | I | AWS Backup vault/plan/selection | Tagged resources are backed up and one restore is validated. |
| G08 | A | Cross-account/cross-region backup copy | Destination recovery works and source role cannot delete protected copy. |
| G09 | I | Budget and cost-allocation tags | Untagged fixture is blocked/reported; threshold notification reaches owner. |
| G10 | I | PR cost estimation | Material cost increase is shown before approval; limitations are documented. |
| G11 | I | Ephemeral environment TTL/cleanup | Expired environment is removed without touching shared resources. |
| G12 | A | Service quota monitoring/request workflow | Scale plan identifies quota and request lead time before deployment. |
| G13 | A | Load/capacity test | Bottleneck and scaling behavior are measured against workload-specific target. |
| G14 | A | AWS Fault Injection Service experiment | Approved blast radius causes expected recovery and alarms. |
| G15 | A | Well-Architected review evidence | Risks and remediation owners map to all six pillars. |

## H. CI/CD, teams, registry, and platform engineering

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| H01 | B | Pre-commit format/validate | Bad formatting and invalid HCL fail locally/CI. |
| H02 | I | PR plan workflow | PR receives readable plan; workflow has no apply permission. |
| H03 | I | GitHub OIDC provider and scoped role | Approved subject assumes role; wrong repo/branch/environment fails. |
| H04 | I | Protected production apply | Required reviewer and environment protection are enforced. |
| H05 | I | Apply serialization per state | Two queued runs cannot apply concurrently. |
| H06 | I | Plan artifact handling | Artifact is encrypted/access-controlled/short-lived and never public. |
| H07 | I | Lint + security + test quality gates | Broken fixtures prove each gate can fail the pipeline. |
| H08 | A | Reusable CI workflow across roots | Consumer passes only documented inputs; central fix updates safely. |
| H09 | A | Separate plan/apply IAM policies | Plan cannot mutate; apply has only root-required actions where practical. |
| H10 | A | Module release automation | Tag/release requires tests, docs, changelog, and approval. |
| H11 | A | Public/private registry publication | Consumer discovers version/docs and pins a tested release. |
| H12 | A | Automated dependency update | Provider/module update opens PR with plan/tests and no auto-production apply. |
| H13 | A | Ownership and CODEOWNERS | Network/security/module changes request correct reviewers. |
| H14 | A | Policy exception workflow | Exception is narrow, approved, auditable, and expires. |
| H15 | A | Self-service golden path | Developer provisions approved service without broad cloud admin access. |
| H16 | A | Platform scorecard | Version, tests, owner, docs, drift, and policy status are visible. |

## I. Multi-account, multi-region, hybrid, and disaster recovery

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| I01 | I | Separate dev/stage/prod AWS accounts and roles | Credentials/resources cannot cross environment accidentally. |
| I02 | A | Organizations, OUs, and account baseline | New sandbox account receives required baseline controls. |
| I03 | A | Control Tower coexistence | Terraform ownership does not conflict with Control Tower-managed resources. |
| I04 | A | Delegated security/logging administrators | Organization services report centrally with scoped administration. |
| I05 | A | Cross-account DNS and certificate workflow | Ownership/validation works without sharing broad credentials. |
| I06 | A | Shared services/egress/network account | Route and inspection ownership boundaries are tested. |
| I07 | A | Two-region provider alias deployment | Resources and state are correctly separated/labeled by region. |
| I08 | A | Backup-and-restore DR | Restore runbook meets workload’s measured RTO/RPO target. |
| I09 | A | Pilot-light DR | Minimal secondary resources scale/activate through tested procedure. |
| I10 | A | Warm-standby DR | Traffic shift and capacity increase work; failback is included. |
| I11 | A | Active/active regional service | Routing and data consistency behavior are proven under one-region impairment. |
| I12 | A | Route 53 failover/ARC routing controls | Safety rules and health behavior prevent unsafe simultaneous changes. |
| I13 | A | Hybrid DNS resolution | On-premises and VPC names resolve only in intended directions. |
| I14 | A | Regional dependency inventory | “Global” and regional service assumptions are documented/tested. |
| I15 | A | Full game day | Failure, communications, recovery, failback, evidence, and improvements are recorded. |

## J. Brownfield, migration, refactoring, upgrades, and incident drills

| ID | Level | Scenario and suggested boundary | Specific proof |
|---|---|---|---|
| J01 | I | Import an existing S3 bucket with `import` block | First accepted plan has no unintended remote changes. |
| J02 | I | Bulk brownfield import and generated-config review | Generated code is normalized and every change is reviewed. |
| J03 | I | Rename resource with `moved` block | Plan shows address move and no destroy/create. |
| J04 | A | Move resources into a child module | State addresses migrate with no infrastructure recreation. |
| J05 | A | Split monolith state | Both new roots plan no-op and have independent locking/permissions. |
| J06 | A | `removed` block / handoff from Terraform ownership | Resource remains or is destroyed exactly per reviewed intent. |
| J07 | I | Provider minor/major upgrade | Changelog reviewed; lockfile intentional; tests and sandbox apply pass. |
| J08 | I | Terraform CLI upgrade | Compatibility tests and plans pass before team rollout. |
| J09 | A | Module major-version consumer migration | Upgrade guide is followed and rollback/forward-fix path is known. |
| J10 | I | Failed apply caused by IAM denial | Partial success is inventoried; permission fixed; repeat apply converges. |
| J11 | I | Interrupted apply | Remote reality and state are inspected before safe continuation. |
| J12 | A | Provider/API throttling or outage | Retry/stop criteria prevent unsafe repeated mutation. |
| J13 | A | State lock held by crashed job | Job ownership is checked; safe unlock process is audited. |
| J14 | A | Resource deleted out of band | Team chooses restore/recreate/remove based on declared ownership and data risk. |
| J15 | A | Secret compromise/rotation | Credential is revoked/rotated and pipeline/workload recover without committing secret. |
| J16 | A | Certificate expiration/renewal failure | Alarm triggers and renewal ownership/runbook restores valid TLS. |
| J17 | A | Quota exhaustion during scale/deploy | Deployment fails safely; quota/capacity fallback procedure works. |
| J18 | A | Database engine/parameter change requiring downtime | Maintenance, snapshot, rollback, and app compatibility are rehearsed. |
| J19 | A | Accidental destroy request | CI/IAM/data protection layers stop it or recovery drill uses validated backup. |
| J20 | A | Decommission service/account | Dependency inventory, retention, export, destroy, DNS/IAM cleanup, and cost-zero check pass. |
| J21 | A | Compliance evidence request | Commit, approvals, plan/apply log, policy results, CloudTrail, and ownership are retrievable. |
| J22 | A | Incident postmortem and control improvement | Corrective action becomes a tested module/policy/runbook change. |

## Suggested tracks

- **Application infrastructure engineer:** A01–A15, B01–B12, C01–C10, D01–D14, E01–E15, G01–G11, H01–H09, J01–J18.
- **Network/platform engineer:** all A/B, C01–C20, F, G, H, I, J.
- **Data platform engineer:** A/B/C foundations, E01–E20, F/G/H, relevant I/J.
- **Enterprise IaC/platform owner:** complete every section and require capstone evidence.

Do not chase row count. Depth means proving behavior, operating failure, and explaining tradeoffs—not merely getting `terraform apply` to succeed.
