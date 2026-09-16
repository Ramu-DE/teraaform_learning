# Minimal Example

Consumes one `service` child module for a private API and exports its normalized contract.

```bash
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
```

Only a local built-in `terraform_data` resource is tracked.
