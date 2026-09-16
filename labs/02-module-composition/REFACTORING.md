# Refactoring Exercise — Rename a Module Call Without Recreation

Terraform state addresses include module call labels. Renaming `module "service"` to `module "workload"` without declaring the move makes Terraform propose destroying old addresses and creating new ones, even when implementation is unchanged.

Use a disposable copy of this lab or commit your work before starting.

## 1. Establish state

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform apply
terraform state list
```

State includes addresses such as:

```text
module.service["api"].terraform_data.this
module.service["frontend"].terraform_data.this
module.service["worker"].terraform_data.this
```

## 2. Rename the module call and references

In `main.tf`, rename:

```hcl
module "service" {
```

to:

```hcl
module "workload" {
```

Update the routing expression from `module.service` to `module.workload`. Update the `service_contracts` output in `outputs.tf` the same way.

Do not plan yet.

## 3. Declare the address migration

Create `moved.tf`:

```hcl
moved {
  from = module.service
  to   = module.workload
}
```

This module-level move covers the corresponding `for_each` instances because their keys are unchanged.

## 4. Verify before apply

```bash
terraform fmt -check -recursive
terraform plan
```

The plan should report module address moves and **zero resources to add, change, or destroy**. If it proposes replacement, stop and inspect every reference and key.

Apply and inspect the new addresses:

```bash
terraform apply
terraform state list
terraform plan -detailed-exitcode
```

The final plan should return exit code `0`.

## 5. Keep migration history

Do not immediately delete the `moved` block from a released module/root. Consumers upgrading from the old address still need it. Remove historical moved blocks only under a deliberate support/version policy.

## 6. Cleanup

```bash
terraform destroy
rm -rf .terraform terraform.tfstate terraform.tfstate.backup terraform.tfvars
```

## Why not `terraform state mv`?

`terraform state mv` can perform one operator's migration, but the declarative `moved` block is reviewable, repeatable for every environment, testable in CI, and travels with the code. CLI state commands remain useful for exceptional migrations but require backups and stronger operational control.
