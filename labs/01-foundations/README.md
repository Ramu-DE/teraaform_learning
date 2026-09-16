# Lab 01 — Terraform Foundations Without Cloud Resources

## Goal

Practice the Terraform workflow and language before introducing AWS credentials, cost, or provider behavior. This configuration uses only Terraform's built-in `terraform_data` resource. It does not download an external provider or create cloud infrastructure.

## Concepts practiced

- Terraform version constraints and root-module files.
- Primitive, map, object, and collection types.
- Defaults, custom validation, locals, comprehensions, `sort`, `sum`, and `merge`.
- Stable `for_each` resource addresses.
- Implicit dependencies through expressions.
- Resource preconditions and top-level check blocks.
- Outputs as a module/deployment contract.
- Native `.tftest.hcl` plan, apply, assertion, and expected-failure tests.
- Local state, no-op plans, and cleanup.

## Files

| File | Purpose |
|---|---|
| `versions.tf` | Terraform CLI compatibility contract. |
| `variables.tf` | Typed inputs, defaults, and validation. |
| `main.tf` | Locals, built-in resources, precondition, and checks. |
| `outputs.tf` | Non-sensitive integration outputs. |
| `tests/foundations.tftest.hcl` | Five native test runs. |
| `terraform.tfvars.example` | Safe example values; copy locally when running the lab. |

## Run the lab

From this directory:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
terraform plan -out=foundation.tfplan
terraform show foundation.tfplan
terraform apply foundation.tfplan
terraform output
terraform plan -detailed-exitcode
```

For the last command, exit code `0` means the applied configuration is already converged, `2` means Terraform found changes, and `1` means an error. Do not confuse exit code `2` with a command failure.

The test suite includes one apply run, but its state is isolated and Terraform cleans up test resources. The normal CLI apply creates only local `terraform_data` state entries.

## Read the plan before applying

Explain each item before continuing:

1. Why three `terraform_data.service` instances have addresses keyed by `api`, `frontend`, and `worker`.
2. Why mandatory tags win over the caller's `ManagedBy` value.
3. Which output values are known during planning and which come from resource output after apply.
4. Why `terraform_data.deployment` depends on the service instances without an explicit `depends_on`.
5. What information is stored in `terraform.tfstate` and why it must not be committed even in a provider-free lab.

## Exercises

Perform these one at a time and restore the example afterward.

### 1. Trigger input validation

Set `environment = "qa"`, run `terraform plan`, and interpret the validation message. Try an uppercase/underscore project name and public port `80` as well.

### 2. Observe stable `for_each` addresses

Add this entry under `service_tiers` in a temporary local `.tfvars` file:

```hcl
scheduler = {
  port     = 9100
  replicas = 1
  public   = false
}
```

Apply, then remove only `scheduler`. Confirm the plan does not replace `api`, `frontend`, or `worker`.

### 3. Test precedence in `merge`

Set these additional tags:

```hcl
additional_tags = {
  ManagedBy  = "manual"
  CostCenter = "learning"
}
```

Confirm `ManagedBy` remains `Terraform` while `CostCenter` is preserved. Reverse the arguments to `merge` temporarily and observe why ordering is part of the contract.

### 4. Trigger a resource precondition

In `dev`, configure a service with six replicas. Variable validation permits up to ten, but the resource precondition limits non-production to five. Change the environment to `prod` and explain why the same replica count passes.

### 5. Trigger a non-blocking check

Make every service public on port 443. The `private_service_exists` check reports a warning because the model no longer contains a protected backend. Restore at least one private service.

### 6. Write a test first

Add a failing assertion that every deployment name ends in the environment. Then implement or correct the expression and rerun `terraform test` until it passes.

## Acceptance criteria

- [ ] `terraform fmt -check -recursive` passes.
- [ ] `terraform init -backend=false` completes without installing an external provider.
- [ ] `terraform validate` succeeds.
- [ ] All five test runs pass, including expected invalid-input cases.
- [ ] The reviewed plan contains only built-in `terraform_data` resources.
- [ ] Apply succeeds and outputs match the input contract.
- [ ] A second plan returns exit code `0` with no changes.
- [ ] Destroy removes all tracked resources.
- [ ] No state, plan, `.terraform/`, or local `.tfvars` is committed.

## Cleanup

Destroy the tracked local resources:

```bash
terraform destroy
```

After destroy, optional local artifact cleanup is:

```bash
rm -rf .terraform terraform.tfstate terraform.tfstate.backup foundation.tfplan terraform.tfvars
```

Run that command only from this lab directory. It removes generated local artifacts, not source files.

## Next lab

Extract the service behavior into a reusable child module with its own contract, examples, provider requirements, and tests. Then compose multiple instances from a root module before introducing AWS.
