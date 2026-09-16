# Complete Example

Instantiates service modules with `for_each`, passes their contracts into the sibling routing module, and exports the resulting routes and summary.

```bash
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform output
terraform plan -detailed-exitcode
terraform destroy
```

Expected composition: two service contracts, one public route, and no cloud resources.
