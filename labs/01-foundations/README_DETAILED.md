# Lab 01: Terraform Foundations 🏗️

## 📋 Overview

This lab introduces you to Terraform fundamentals through hands-on practice. You'll learn the core workflow, resource management, and testing strategies that form the foundation of Infrastructure as Code.

## 🎯 Learning Objectives

By the end of this lab, you will:

- ✅ Understand Terraform's core workflow (init, plan, apply, destroy)
- ✅ Create and manage AWS resources with Terraform
- ✅ Use variables, outputs, and locals effectively
- ✅ Work with data sources to query existing infrastructure
- ✅ Write and execute Terraform tests
- ✅ Follow best practices for configuration organization

## ⏱️ Estimated Time

**2-3 hours** (including reading, implementation, and testing)

## 📁 Lab Structure

```
01-foundations/
├── README.md              # Lab documentation (this file)
├── main.tf                # Core resource definitions
├── variables.tf           # Input variable declarations
├── outputs.tf             # Output value definitions
├── data.tf                # Data source queries
├── providers.tf           # Provider configuration
├── terraform.tfvars       # Variable values (gitignored)
├── .gitignore            # Git ignore patterns
│
├── tests/                # Terraform native tests
│   ├── main.tftest.hcl   # Main test suite
│   └── validation.tftest.hcl  # Validation tests
│
└── docs/                 # Additional documentation
    ├── architecture.md   # Architecture decisions
    └── troubleshooting.md # Common issues
```

## 🔄 Terraform Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                   TERRAFORM CORE WORKFLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐                                                   │
│  │  WRITE   │  Create .tf files with infrastructure definitions │
│  └────┬─────┘                                                   │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────┐                                                   │
│  │   INIT   │  terraform init                                   │
│  │          │  • Download providers (AWS, etc.)                 │
│  │          │  • Initialize backend (local/remote)              │
│  │          │  • Set up plugin cache                            │
│  └────┬─────┘                                                   │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────┐                                                   │
│  │   PLAN   │  terraform plan                                   │
│  │          │  • Read configuration files                       │
│  │          │  • Query current state                            │
│  │          │  • Calculate differences                          │
│  │          │  • Show preview of changes                        │
│  └────┬─────┘                                                   │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────┐                                                   │
│  │  APPLY   │  terraform apply                                  │
│  │          │  • Execute planned changes                        │
│  │          │  • Create/update/delete resources                 │
│  │          │  • Update state file                              │
│  │          │  • Display outputs                                │
│  └────┬─────┘                                                   │
│       │                                                          │
│       │     ┌──────────────────┐                               │
│       ├────→│   ITERATE        │ Make changes & reapply        │
│       │     └──────────────────┘                               │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────┐                                                   │
│  │ DESTROY  │  terraform destroy                                │
│  │          │  • Remove all managed resources                   │
│  │          │  • Clean up state                                 │
│  └──────────┘                                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🏗️ Architecture Overview

### What We're Building

This lab creates a simple but complete AWS infrastructure:

```
┌────────────────────────────────────────────────────────────────┐
│                         AWS Account                             │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │                      VPC (Optional)                    │    │
│  │                  10.0.0.0/16                           │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────┐    │    │
│  │  │           Security Group                      │    │    │
│  │  │  • SSH: 22 (from your IP)                    │    │    │
│  │  │  • HTTP: 80 (from anywhere)                  │    │    │
│  │  │  • HTTPS: 443 (from anywhere)                │    │    │
│  │  └──────────────────────────────────────────────┘    │    │
│  │                          │                             │    │
│  │                          ▼                             │    │
│  │  ┌──────────────────────────────────────────────┐    │    │
│  │  │         EC2 Instance (t2.micro)              │    │    │
│  │  │  • Amazon Linux 2                            │    │    │
│  │  │  • Public IP                                 │    │    │
│  │  │  • SSH key pair                              │    │    │
│  │  │  • User data script                          │    │    │
│  │  └──────────────────────────────────────────────┘    │    │
│  │                                                        │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │                 S3 Bucket                              │    │
│  │  • Versioning enabled                                  │    │
│  │  • Server-side encryption                              │    │
│  │  • Private access only                                 │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### Resource Relationships

```
┌─────────────────────────────────────────────────────────┐
│               RESOURCE DEPENDENCIES                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  data.aws_ami                                           │
│       │                                                  │
│       │ provides AMI ID                                 │
│       ▼                                                  │
│  aws_instance ─────────depends on─────→ aws_key_pair    │
│       │                                      ↑           │
│       │                                      │           │
│       └──────depends on──────→ aws_security_group       │
│                                              ↑           │
│                                              │           │
│                                    optional VPC dependency│
│                                                          │
│  aws_s3_bucket (independent)                            │
│       │                                                  │
│       └── aws_s3_bucket_versioning                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 📖 Step-by-Step Guide

### Step 1: Initialize Your Workspace

```bash
# Navigate to the lab directory
cd labs/01-foundations

# View the structure
tree -L 2

# Read the main configuration
cat main.tf
```

### Step 2: Configure Variables

Create `terraform.tfvars`:

```hcl
# terraform.tfvars
aws_region = "us-east-1"
environment = "dev"
project_name = "terraform-lab01"

# Optionally customize
instance_type = "t2.micro"
enable_monitoring = true
```

### Step 3: Initialize Terraform

```bash
terraform init
```

**What happens:**
- Downloads AWS provider plugin
- Initializes local backend
- Creates `.terraform` directory
- Generates lock file

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
# Check syntax and consistency
terraform validate

# Format code
terraform fmt

# View configuration
terraform show
```

### Step 5: Plan Infrastructure

```bash
# Create execution plan
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan

# Review detailed plan
terraform show tfplan
```

**Understanding the Plan:**

```
Terraform will perform the following actions:

  # aws_instance.main will be created
  + resource "aws_instance" "main" {
      + ami                         = "ami-xxxxx"
      + instance_type               = "t2.micro"
      + availability_zone           = (known after apply)
      + id                          = (known after apply)
      + public_ip                   = (known after apply)
      ...
    }

  # aws_s3_bucket.main will be created
  + resource "aws_s3_bucket" "main" {
      + bucket                      = "terraform-lab01-dev-xxxxx"
      + id                          = (known after apply)
      ...
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

### Step 6: Apply Configuration

```bash
# Apply changes (will prompt for confirmation)
terraform apply

# Or apply saved plan
terraform apply tfplan

# Auto-approve (use carefully!)
terraform apply -auto-approve
```

**What happens during apply:**

```
┌──────────────────────────────────────────────────┐
│          APPLY EXECUTION FLOW                     │
├──────────────────────────────────────────────────┤
│                                                   │
│  1. Lock State                                   │
│     └─ Prevent concurrent modifications          │
│                                                   │
│  2. Refresh State                                │
│     └─ Query current infrastructure              │
│                                                   │
│  3. Build Dependency Graph                       │
│     └─ Determine resource order                  │
│                                                   │
│  4. Execute Actions                              │
│     ├─ Create resources (parallel when possible) │
│     ├─ Update existing resources                 │
│     └─ Delete marked resources                   │
│                                                   │
│  5. Update State File                            │
│     └─ Record new infrastructure state           │
│                                                   │
│  6. Display Outputs                              │
│     └─ Show configured output values             │
│                                                   │
│  7. Unlock State                                 │
│     └─ Allow future operations                   │
│                                                   │
└──────────────────────────────────────────────────┘
```

### Step 7: Verify Resources

```bash
# List all managed resources
terraform state list

# Show specific resource details
terraform state show aws_instance.main

# View outputs
terraform output

# Get specific output
terraform output instance_public_ip
```

### Step 8: Test Infrastructure

```bash
# Run Terraform tests
terraform test

# Run specific test file
terraform test -filter=tests/main.tftest.hcl

# Verbose output
terraform test -verbose
```

### Step 9: Make Changes

Try modifying resources:

```hcl
# In main.tf, change instance type
resource "aws_instance" "main" {
  instance_type = "t2.small"  # Changed from t2.micro
  # ... rest of config
}
```

Then:

```bash
terraform plan    # See what will change
terraform apply   # Apply the change
```

### Step 10: Clean Up

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy with auto-approval
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.main
```

## 🔍 Key Concepts Explained

### Variables

**Purpose:** Make configurations flexible and reusable

```hcl
# Declaration (variables.tf)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = contains(["t2.micro", "t2.small"], var.instance_type)
    error_message = "Instance type must be t2.micro or t2.small."
  }
}

# Usage (main.tf)
resource "aws_instance" "main" {
  instance_type = var.instance_type
}

# Assignment (terraform.tfvars)
instance_type = "t2.small"
```

### Outputs

**Purpose:** Export values for use in other modules or for display

```hcl
# Definition (outputs.tf)
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

# Access after apply
$ terraform output instance_public_ip
"54.123.45.67"
```

### Locals

**Purpose:** Define reusable expressions within a module

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
  
  bucket_name = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
}

# Usage
resource "aws_instance" "main" {
  tags = local.common_tags
}
```

### Data Sources

**Purpose:** Query existing resources or information

```hcl
# Query latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use in resource
resource "aws_instance" "main" {
  ami = data.aws_ami.amazon_linux_2.id
}
```

## 🧪 Testing Strategy

```
┌────────────────────────────────────────────────────┐
│              TESTING PYRAMID                        │
├────────────────────────────────────────────────────┤
│                                                     │
│                    ▲                               │
│                   ╱ ╲                              │
│                  ╱   ╲  Integration Tests          │
│                 ╱     ╲ (terraform test)           │
│                ╱───────╲                           │
│               ╱         ╲                          │
│              ╱  Validation╲                        │
│             ╱    Tests     ╲                       │
│            ╱───────────────╲                       │
│           ╱                 ╲                      │
│          ╱   Syntax & Lint   ╲                    │
│         ╱  (fmt, validate)    ╲                   │
│        ╱───────────────────────╲                  │
│                                                     │
└────────────────────────────────────────────────────┘
```

### Test Types

1. **Syntax Tests** (terraform validate)
   - Check HCL syntax
   - Verify provider schemas
   - Validate variable references

2. **Plan Tests** (terraform test with command = plan)
   - Verify resource configuration
   - Check computed attributes
   - Test variable validation

3. **Apply Tests** (terraform test with command = apply)
   - Actually create resources
   - Verify real-world behavior
   - Test complete workflows

### Example Test

```hcl
# tests/main.tftest.hcl
run "verify_instance_type" {
  command = plan
  
  variables {
    instance_type = "t2.micro"
  }
  
  assert {
    condition     = aws_instance.main.instance_type == "t2.micro"
    error_message = "Instance type must match the variable"
  }
}

run "verify_bucket_encryption" {
  command = apply
  
  assert {
    condition     = aws_s3_bucket.main.server_side_encryption_configuration != null
    error_message = "S3 bucket must have encryption enabled"
  }
}
```

## 🔐 Security Best Practices

### Implemented in This Lab

✅ **Least Privilege:**
- Security groups restrict access
- S3 bucket blocks public access

✅ **Encryption:**
- S3 uses server-side encryption
- Data in transit uses HTTPS

✅ **Secret Management:**
- Never commit `terraform.tfvars`
- Use environment variables for sensitive data
- Store state securely

✅ **Resource Tagging:**
- All resources tagged for tracking
- Environment and ownership clear

### Security Checklist

```
□ .gitignore includes sensitive files
□ No hardcoded credentials in .tf files
□ Security groups follow least privilege
□ Encryption enabled on storage
□ Access logging configured
□ Resource tags applied
□ State file secured
```

## 📊 State Management

### Understanding State

```
┌──────────────────────────────────────────────────┐
│         TERRAFORM STATE LIFECYCLE                 │
├──────────────────────────────────────────────────┤
│                                                   │
│  terraform apply                                 │
│       │                                           │
│       ├─→ Read terraform.tfstate                 │
│       │                                           │
│       ├─→ Query actual infrastructure (AWS)      │
│       │                                           │
│       ├─→ Calculate diff                         │
│       │                                           │
│       ├─→ Apply changes to AWS                   │
│       │                                           │
│       └─→ Update terraform.tfstate               │
│                                                   │
│  terraform.tfstate contains:                     │
│  ├─ Resource IDs                                 │
│  ├─ Attribute values                             │
│  ├─ Dependencies                                 │
│  └─ Metadata                                     │
│                                                   │
└──────────────────────────────────────────────────┘
```

### State Commands

```bash
# List resources in state
terraform state list

# Show details of a resource
terraform state show aws_instance.main

# Remove resource from state (danger!)
terraform state rm aws_instance.main

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Pull state to stdout
terraform state pull

# Push state from file
terraform state push terraform.tfstate
```

## 🐛 Troubleshooting

### Common Issues

**Issue: "Error acquiring the state lock"**
```bash
# Solution: Remove stale lock (carefully!)
terraform force-unlock <lock-id>
```

**Issue: "Resource already exists"**
```bash
# Solution: Import existing resource
terraform import aws_instance.main i-1234567890abcdef0
```

**Issue: "Provider configuration not present"**
```bash
# Solution: Re-initialize
terraform init -upgrade
```

**Issue: "Invalid value for variable"**
```bash
# Solution: Check terraform.tfvars or pass via CLI
terraform apply -var="instance_type=t2.micro"
```

## 📈 Next Steps

After completing this lab:

1. ✅ Experiment with different resource types
2. ✅ Try modifying variables and seeing the impact
3. ✅ Write additional tests
4. ✅ Explore the AWS Console to see created resources
5. ✅ Move on to [Lab 02: Module Composition](../02-module-composition/README.md)

## 📚 Additional Resources

- [Terraform CLI Documentation](https://www.terraform.io/cli)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language Documentation](https://www.terraform.io/language)
- [Terraform Testing](https://www.terraform.io/language/modules/testing)

## 🎓 Knowledge Check

Test your understanding:

1. What is the purpose of `terraform init`?
2. What's the difference between `plan` and `apply`?
3. How do you reference a variable in a resource?
4. What is a data source and when would you use one?
5. How does Terraform track infrastructure state?

[View answers in docs/knowledge-check.md](./docs/knowledge-check.md)

---

**🎉 Congratulations!** You've completed Lab 01. You now understand Terraform fundamentals and are ready for more advanced topics!

[**→ Continue to Lab 02: Module Composition**](../02-module-composition/README.md)
