# Lab 02: Module Composition 🧩

## 📋 Overview

This lab teaches you how to build reusable, composable Terraform modules. You'll learn to design modular architectures, create child modules, and compose complex systems from simple building blocks.

## 🎯 Learning Objectives

By the end of this lab, you will:

- ✅ Design and implement reusable Terraform modules
- ✅ Understand module input/output contracts
- ✅ Compose complex infrastructure from simple components
- ✅ Pass data between modules effectively
- ✅ Test module behavior in isolation
- ✅ Follow module best practices

## ⏱️ Estimated Time

**3-4 hours** (including implementation, testing, and experimentation)

## 📁 Lab Structure

```
02-module-composition/
├── README.md                 # Lab documentation
├── main.tf                   # Root module - composes child modules
├── variables.tf              # Root module inputs
├── outputs.tf                # Root module outputs
├── providers.tf              # Provider configuration
├── terraform.tfvars.example  # Example variable values
│
├── modules/                  # Child modules
│   ├── vpc/                  # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── security_groups/      # Security groups module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   └── compute/              # Compute module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── examples/                 # Usage examples
│   ├── basic/                # Basic usage
│   ├── advanced/             # Advanced patterns
│   └── multi-env/            # Multi-environment setup
│
└── tests/                    # Module tests
    ├── vpc_test.tftest.hcl
    ├── security_groups_test.tftest.hcl
    └── integration_test.tftest.hcl
```

## 🏗️ Module Architecture

### Three-Tier Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                         ROOT MODULE                                 │
│                    (main.tf orchestrator)                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │
│  │  VPC Module  │      │Security Group│      │    Compute   │    │
│  │              │─────▶│   Module     │─────▶│    Module    │    │
│  │              │      │              │      │              │    │
│  └──────────────┘      └──────────────┘      └──────────────┘    │
│         │                     │                      │             │
│         │                     │                      │             │
│         ▼                     ▼                      ▼             │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                      AWS CLOUD                            │    │
│  │                                                           │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │          VPC (10.0.0.0/16)                      │    │    │
│  │  │                                                  │    │    │
│  │  │  ┌──────────────┐        ┌──────────────┐     │    │    │
│  │  │  │ Public Subnet │        │Private Subnet│     │    │    │
│  │  │  │ 10.0.1.0/24  │        │ 10.0.2.0/24  │     │    │    │
│  │  │  │              │        │              │     │    │    │
│  │  │  │  ┌────────┐  │        │  ┌────────┐  │     │    │    │
│  │  │  │  │  SG    │  │        │  │  SG    │  │     │    │    │
│  │  │  │  │ Rules  │  │        │  │ Rules  │  │     │    │    │
│  │  │  │  └────────┘  │        │  └────────┘  │     │    │    │
│  │  │  │      │       │        │      │       │     │    │    │
│  │  │  │  ┌────────┐  │        │  ┌────────┐  │     │    │    │
│  │  │  │  │  EC2   │  │        │  │  RDS   │  │     │    │    │
│  │  │  │  │Instance│  │        │  │Instance│  │     │    │    │
│  │  │  │  └────────┘  │        │  └────────┘  │     │    │    │
│  │  │  └──────────────┘        └──────────────┘     │    │    │
│  │  │                                                  │    │    │
│  │  │  ┌────────────┐           ┌────────────┐       │    │    │
│  │  │  │    IGW     │           │    NAT     │       │    │    │
│  │  │  │  Gateway   │           │  Gateway   │       │    │    │
│  │  │  └────────────┘           └────────────┘       │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

## 🔄 Module Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│              MODULE DATA FLOW                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐                                            │
│  │ Root Module │                                            │
│  │  Variables  │                                            │
│  └──────┬──────┘                                            │
│         │                                                    │
│         ├──── var.vpc_cidr ─────────────┐                  │
│         │                                 ▼                  │
│         │                       ┌──────────────────┐        │
│         │                       │   VPC Module     │        │
│         │                       │                  │        │
│         │                       │ Input: vpc_cidr  │        │
│         │                       │ Creates: VPC,    │        │
│         │                       │   Subnets, IGW   │        │
│         │                       │ Output: vpc_id,  │        │
│         │                       │   subnet_ids     │        │
│         │                       └────────┬─────────┘        │
│         │                                │                  │
│         │    Output: vpc_id ─────────────┤                  │
│         │            subnet_ids ──────────┤                  │
│         │                                │                  │
│         ├──── var.allowed_ips ───────┐   │                  │
│         │                             ▼   ▼                  │
│         │                  ┌──────────────────────┐         │
│         │                  │ Security Group Module│         │
│         │                  │                      │         │
│         │                  │ Input: vpc_id,       │         │
│         │                  │   allowed_cidrs      │         │
│         │                  │ Creates: SGs, Rules  │         │
│         │                  │ Output: sg_ids       │         │
│         │                  └─────────┬────────────┘         │
│         │                            │                      │
│         │    Output: web_sg_id ──────┤                      │
│         │            app_sg_id ──────┤                      │
│         │                            │                      │
│         ├──── var.instance_type ─┐   │                      │
│         │                         ▼   ▼                      │
│         │            ┌──────────────────────────┐           │
│         │            │   Compute Module         │           │
│         │            │                          │           │
│         │            │ Input: subnet_ids,       │           │
│         │            │   security_group_ids,    │           │
│         │            │   instance_type          │           │
│         │            │ Creates: EC2 instances   │           │
│         │            │ Output: instance_ids,    │           │
│         │            │   public_ips             │           │
│         │            └─────────┬────────────────┘           │
│         │                      │                            │
│         │                      │                            │
│         └──────────────────────┘                            │
│                 Final Outputs                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📖 Step-by-Step Guide

### Step 1: Understand Module Structure

A well-designed module has:

```
module-name/
├── main.tf           # Resource definitions
├── variables.tf      # Input declarations
├── outputs.tf        # Output definitions
├── README.md         # Module documentation
├── versions.tf       # Provider requirements (optional)
└── examples/         # Usage examples (optional)
```

### Step 2: Create VPC Module

**Module Design:**

```hcl
# modules/vpc/main.tf

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index + 1}"
      Type = "Public"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}
```

**Module Interface:**

```hcl
# modules/vpc/variables.tf

variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

# modules/vpc/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
```

### Step 3: Create Security Groups Module

```hcl
# modules/security_groups/main.tf

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Security group for web tier"
  vpc_id      = var.vpc_id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-web-sg"
      Tier = "Web"
    }
  )
}

resource "aws_security_group_rule" "web_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTP traffic"
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
}

# Application tier security group
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Security group for application tier"
  vpc_id      = var.vpc_id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-app-sg"
      Tier = "Application"
    }
  )
}

# Allow traffic from web tier
resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow traffic from web tier"
}
```

### Step 4: Create Compute Module

```hcl
# modules/compute/main.tf

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]
  
  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = data.aws_ami.this.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  
  user_data = var.user_data
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-instance-${count.index + 1}"
    }
  )
}
```

### Step 5: Compose Modules in Root

```hcl
# main.tf (root module)

# Call VPC module
module "vpc" {
  source = "./modules/vpc"
  
  name                 = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  
  tags = local.common_tags
}

# Call Security Groups module
module "security_groups" {
  source = "./modules/security_groups"
  
  name          = var.project_name
  vpc_id        = module.vpc.vpc_id  # Output from VPC module
  allowed_cidrs = var.allowed_cidrs
  
  tags = local.common_tags
}

# Call Compute module
module "compute" {
  source = "./modules/compute"
  
  name               = var.project_name
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  subnet_ids         = module.vpc.public_subnet_ids  # From VPC
  security_group_ids = [module.security_groups.web_sg_id]  # From SG module
  
  tags = local.common_tags
}

# Root module outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "instance_public_ips" {
  description = "Public IPs of created instances"
  value       = module.compute.public_ips
}
```

## 🎨 Module Design Patterns

### Pattern 1: Single Responsibility

Each module should have one clear purpose:

```
✅ GOOD:
  modules/vpc/         - Only creates VPC and subnets
  modules/compute/     - Only creates compute resources

❌ BAD:
  modules/everything/  - Creates VPC, compute, databases, etc.
```

### Pattern 2: Clear Interface

Define explicit inputs and outputs:

```hcl
# Clear, well-documented interface
variable "vpc_cidr" {
  description = "CIDR block for VPC. Must be a valid IPv4 CIDR."
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

output "vpc_id" {
  description = "ID of the VPC for use in other modules"
  value       = aws_vpc.main.id
}
```

### Pattern 3: Composition Over Configuration

Build complex systems by composing simple modules:

```
Complex Infrastructure = VPC + Security + Compute + Database
                         ↓     ↓         ↓        ↓
                      Modules composed in root module
```

### Pattern 4: Sensible Defaults

Provide defaults for optional variables:

```hcl
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true  # Sensible default
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"  # Cost-effective default
}
```

## 🧪 Testing Modules

### Test Hierarchy

```
┌──────────────────────────────────────────┐
│         MODULE TESTING STRATEGY           │
├──────────────────────────────────────────┤
│                                           │
│  1. Unit Tests (Per Module)              │
│     ├─ Test module in isolation          │
│     ├─ Mock dependencies                 │
│     └─ Validate outputs                  │
│                                           │
│  2. Integration Tests                    │
│     ├─ Test modules together             │
│     ├─ Verify data passing               │
│     └─ Check resource creation           │
│                                           │
│  3. End-to-End Tests                     │
│     ├─ Test complete infrastructure      │
│     ├─ Verify functionality              │
│     └─ Test real workloads               │
│                                           │
└──────────────────────────────────────────┘
```

### Example Module Test

```hcl
# tests/vpc_test.tftest.hcl

mock_provider "aws" {}

variables {
  name     = "test-vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

run "validate_vpc_cidr" {
  command = plan
  
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR must match input variable"
  }
}

run "validate_subnet_count" {
  command = plan
  
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets"
  }
}

run "validate_outputs" {
  command = apply
  
  assert {
    condition     = output.vpc_id != ""
    error_message = "VPC ID output must not be empty"
  }
  
  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Must output 2 subnet IDs"
  }
}
```

## 📊 Module Versioning

### Version Control Strategy

```
┌──────────────────────────────────────────┐
│       MODULE VERSION STRATEGY             │
├──────────────────────────────────────────┤
│                                           │
│  Local Modules (Development)             │
│  └─ source = "./modules/vpc"             │
│     • Easy to modify                     │
│     • Fast iteration                     │
│                                           │
│  Git Modules (Shared)                    │
│  └─ source = "git::https://..."          │
│     • Version controlled                 │
│     • Shared across teams                │
│                                           │
│  Registry Modules (Production)           │
│  └─ source = "terraform-aws-modules/..."│
│     • Official/community tested          │
│     • Semantic versioning                │
│                                           │
└──────────────────────────────────────────┘
```

### Using Git Modules

```hcl
# Reference specific version
module "vpc" {
  source = "git::https://github.com/org/terraform-modules.git//vpc?ref=v1.2.0"
  
  # Module inputs
  vpc_cidr = "10.0.0.0/16"
}

# Reference branch
module "vpc_dev" {
  source = "git::https://github.com/org/terraform-modules.git//vpc?ref=develop"
  
  vpc_cidr = "10.1.0.0/16"
}
```

## 🔍 Best Practices

### ✅ DO

- Keep modules focused on a single responsibility
- Document all variables and outputs
- Provide examples of module usage
- Write tests for modules
- Use semantic versioning
- Include README in each module
- Validate variable inputs
- Use consistent naming conventions

### ❌ DON'T

- Create monolithic modules
- Use provider configurations in modules
- Hard-code values
- Ignore outputs users might need
- Skip documentation
- Break backward compatibility without version bump
- Use deprecated features
- Expose unnecessary complexity

## 🎓 Module Checklist

```
□ Module has clear, single responsibility
□ All variables have descriptions
□ All variables have appropriate types
□ Complex variables have validation rules
□ All outputs are documented
□ Module includes README.md
□ Examples directory exists
□ Tests verify module behavior
□ No provider blocks in module
□ Tags are propagated from variables
□ Sensible defaults provided
□ No hard-coded values
```

## 📈 Next Steps

After completing this lab:

1. ✅ Create your own custom modules
2. ✅ Refactor existing code into modules
3. ✅ Explore Terraform Registry modules
4. ✅ Build a module library for your team
5. ✅ Move on to [Lab 03: Remote State Management](../03-remote-state/README.md)

## 📚 Additional Resources

- [Module Development Best Practices](https://www.terraform.io/language/modules/develop)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [Module Composition Patterns](https://www.terraform.io/language/modules/develop/composition)

---

**🎉 Congratulations!** You've mastered module composition. You can now build reusable, composable infrastructure components!

[**→ Continue to Lab 03: Remote State Management**](../03-remote-state/README.md)
