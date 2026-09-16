# Lab 02 — Reusable Modules and Flat Composition

## Goal

Learn to design reusable child modules as stable APIs and compose them from a thin root module. This lab remains provider-free and cost-free: it uses only Terraform's built-in `terraform_data` resource and reserved `.invalid` DNS names.

## Architecture

```text
var.services
    │
    ├── module.service["frontend"] ──┐
    ├── module.service["api"] ───────┼── typed service contracts
    └── module.service["worker"] ────┘
                                      │
                                      ▼
                              module.routing
                                      │
                              public routes only
```

The root is the composition layer. It owns environment, naming, mandatory tags, and the service catalog. Each `service` instance knows nothing about routing. `routing` knows nothing about how services are created; it consumes only their exported contracts. This is dependency inversion and keeps the module tree one level deep.

## Learning objectives

- Distinguish root modules from reusable child modules.
- Define small, typed input and output contracts.
- Instantiate a child module with stable `for_each` keys.
- Wire sibling modules through output/input expressions.
- Understand implicit dependencies across module boundaries.
- Keep provider configurations in roots; reusable modules contain none.
- Test child contracts independently and again in composition.
- Build independently runnable minimal and complete examples.
- Rename a module call without recreating resources by using `moved` blocks.

## Structure

```text
02-module-composition/
├── README.md
├── REFACTORING.md
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── tests/composition.tftest.hcl
├── modules/
│   ├── service/
│   │   ├── README.md
│   │   ├── versions.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── tests/service.tftest.hcl
│   └── routing/
│       ├── README.md
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── tests/routing.tftest.hcl
└── examples/
    ├── minimal/
    └── complete/
```

## Why these are modules

The `service` module raises abstraction from a raw resource to a normalized service contract: stable identifier, endpoint, exposure, route path, scale, and metadata. The `routing` module raises abstraction from individual route resources to the rule “route public service contracts over HTTPS and ignore private contracts.” Neither is merely a wrapper around a resource argument list.

## Provider rule

These modules use `terraform_data`, whose provider is built into Terraform, so no `required_providers` entry is needed. A real AWS child module would declare its provider source and minimum compatible version but still contain no `provider "aws"` configuration:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
```

That version is illustrative, not a recommendation for a future lab. The root selects the tested provider range and configures region/credentials; the child declares only what it requires.

## Run all tests

From this lab directory:

```bash
terraform fmt -check -recursive

terraform -chdir=modules/service init -backend=false
terraform -chdir=modules/service validate
terraform -chdir=modules/service test

terraform -chdir=modules/routing init -backend=false
terraform -chdir=modules/routing validate
terraform -chdir=modules/routing test

terraform init -backend=false
terraform validate
terraform test
```

The 12 runs cover each child module and the root composition. Apply tests create only temporary local `terraform_data` state and Terraform tears them down.

## Run the root lifecycle

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform plan -out=composition.tfplan
terraform show composition.tfplan
terraform apply composition.tfplan
terraform output
terraform plan -detailed-exitcode
```

A no-op final plan returns exit code `0`. Exit code `2` means changes are present, not necessarily that Terraform failed.

## Run the examples

```bash
terraform -chdir=examples/minimal init -backend=false
terraform -chdir=examples/minimal validate
terraform -chdir=examples/minimal plan

terraform -chdir=examples/complete init -backend=false
terraform -chdir=examples/complete validate
terraform -chdir=examples/complete plan
```

The examples are separate root modules. Their relative module sources intentionally differ from the main root.

## Read the graph and contracts

Before applying, explain:

1. Why `module.service["api"]` has a stable key rather than an index.
2. Why `module.routing` depends on every service module without `depends_on`.
3. Why routing receives a map of objects instead of the entire `module.service` object.
4. Why the root, not the service child, owns mandatory tags and environment policy.
5. Why a private contract has no route path and never appears in `routes_by_service`.
6. Why `.invalid` endpoints model interfaces but cannot accidentally resolve publicly.

Optional graph output:

```bash
terraform graph > graph.dot
```

Graphviz is optional and not installed by this lab.

## Exercises

### 1. Add a service safely

Add a private `scheduler` service. Confirm the plan adds only `module.service["scheduler"]...` and updates the routing summary without replacing existing module instances.

### 2. Add another public route

Add an `admin` service on port 443 with `/admin`. Confirm routing creates one new route. Then duplicate `/` and observe root validation fail before apply.

### 3. Change implementation behind the contract

Add a new internal value to the service resource without changing `output.contract`. Explain why routing remains unaffected. Then intentionally rename a contract field and identify why that is a breaking API change.

### 4. Move policy to the correct layer

Try putting the owner tag inside the service module, then reason about reuse by a different root. Restore root ownership. Module authors enforce module invariants; composition roots own deployment policy and context.

### 5. Compare flat and nested designs

Sketch a service module that calls routing internally. List what becomes harder: sharing one router, routing multiple services, independent testing, and replacing routing. Do not implement the nested design.

### 6. Rename the module call safely

Complete [REFACTORING.md](REFACTORING.md). The final plan must show no destroy/create actions after renaming `module.service` to `module.workload` with a `moved` block.

### 7. Test before implementation

Add a failing test requiring route paths to end without a trailing slash except `/`. Implement validation, rerun module tests, and then rerun composition tests.

## Module release thought exercise

Assume `service` is published at `v1.2.0`:

- Adding an optional output is normally backward compatible: minor release.
- Fixing documentation only: patch release.
- Renaming `contract.endpoint`: breaking change requiring a major release.
- Tightening validation can be breaking for existing consumers even if types do not change.
- A local-path module has no independent version; the entire repository commit versions it.

## Acceptance criteria

- [ ] All Terraform files are formatted.
- [ ] Service module initializes, validates, and passes 4 tests independently.
- [ ] Routing module initializes, validates, and passes 4 tests independently.
- [ ] Root initializes, validates, and passes 4 composition tests.
- [ ] Minimal and complete examples initialize and validate independently.
- [ ] No reusable child module contains a provider configuration.
- [ ] Initial root plan contains only expected module resources.
- [ ] Apply succeeds and outputs contain three service contracts and one route.
- [ ] Second root plan is no-op with detailed exit code `0`.
- [ ] The moved-block exercise produces no resource recreation.
- [ ] Destroy empties state and generated artifacts are removed.
- [ ] No external provider or AWS resource is used.

## Cleanup

Destroy each root that you applied before deleting its files:

```bash
terraform destroy
terraform -chdir=examples/minimal destroy
terraform -chdir=examples/complete destroy
```

After destroy, remove local generated artifacts only from this lab:

```bash
find . -type d -name .terraform -prune -exec rm -rf {} +
find . -type f \( -name 'terraform.tfstate*' -o -name '*.tfplan' -o -name 'terraform.tfvars' -o -name 'graph.dot' \) -delete
```

Review `pwd` before running cleanup commands.

## Next lab

Lab 03 will bootstrap and migrate remote state. AWS access will not be used until account identity, region, budget, backend security, and short-lived credentials are explicitly verified.
