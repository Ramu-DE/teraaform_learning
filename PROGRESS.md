# Terraform Learning Progress

Last updated: 2026-09-16

## Environment

- Workspace: `/home/ec2-user/environment/terraform_module`
- Terraform CLI: v1.12.2 on linux_amd64
- Version shown as current by upstream on this date: v1.16.2
- Git: this folder is not currently a Git repository
- AWS resources created by the learning project: none

## Stage 0 — Safety and learning decisions

Status: complete

- AWS is the primary cloud for production scenarios.
- Begin provider-free; do not require credentials or incur cloud charges for the first lab.
- Use disposable sandbox accounts and budgets before AWS labs.
- Keep state, plans, credentials, and local `.tfvars` out of version control.
- Prefer short-lived identity locally and OIDC in CI when cloud work begins.
- Require format, validation, tests, reviewed plan, apply, no-op second plan, and cleanup evidence.
- Do not initialize Git, install tools, or create cloud resources without an implementation need.

## Stage 1 — Terraform foundations

Status: complete and verified

Lab: [`labs/01-foundations`](labs/01-foundations/README.md)

Implemented concepts:

- Types, variables, defaults, and validation.
- Locals and collection transformations.
- Stable `for_each` resource addresses.
- Built-in `terraform_data` resources and local state.
- Preconditions and check blocks.
- Outputs and native Terraform tests.

Verified on 2026-09-16:

- `terraform fmt -check -recursive`: passed.
- `terraform init -backend=false`: passed; only `terraform.io/builtin/terraform` was used.
- `terraform validate`: configuration valid.
- `terraform test`: 5 passed, 0 failed.
- Initial plan: 4 to add, 0 to change, 0 to destroy.
- Apply: 4 local `terraform_data` resources added.
- Outputs: deployment `checkout-dev`, public `frontend`, private `api` and `worker`, total replicas 5.
- Convergence plan: no changes, detailed exit code 0.
- Destroy: 4 resources destroyed; state contained zero resources afterward.
- Cleanup: `.terraform`, local state, saved plan, and local `terraform.tfvars` removed.
- External providers and AWS resources: none.

## Stage 2 — Reusable modules and flat composition

Status: complete and verified

Lab: [`labs/02-module-composition`](labs/02-module-composition/README.md)

Implemented concepts:

- Reusable `service` and `routing` leaf child modules with typed contracts.
- Thin root composition with stable module `for_each` keys.
- Dependency inversion by passing service outputs into sibling routing inputs.
- Root-owned environment, naming, policy, and mandatory tags.
- Independent module tests and minimal/complete consumer examples.
- Declarative module address migration using a `moved` block.

Verified on 2026-09-16:

- `terraform fmt -check -recursive`: passed.
- Service, routing, minimal example, complete example, and composing root all initialized and validated independently.
- Every root used only `terraform.io/builtin/terraform`; child modules contain no provider configurations.
- Service tests: 4 passed, 0 failed.
- Routing tests: 4 passed, 0 failed.
- Composition tests: 4 passed, 0 failed; 12 total test runs passed.
- Root plan/apply: 5 local resources added, exporting 3 service contracts and 1 public route.
- Convergence plan: no changes, detailed exit code 0.
- Root destroy: 5 resources destroyed and state emptied.
- Refactor rehearsal: 3 `module.service` instances moved to `module.workload`; plan reported 0 add, 0 change, 0 destroy and no non-no-op resource actions.
- Post-refactor plan: no changes, detailed exit code 0; disposable state emptied.
- Final source/link/artifact/provider check: 0 errors.
- External providers and AWS resources: none.

## Next milestones

1. Build Lab 03: bootstrap an S3 remote backend with native lockfiles and least-privilege access design.
2. Rehearse local-to-remote state migration and version recovery in an isolated backend root.
3. Verify AWS account identity, region, budget, and short-lived credentials before any cloud apply.
4. Add CI checks for formatting, validation, tests, plan review, and protected state access.
