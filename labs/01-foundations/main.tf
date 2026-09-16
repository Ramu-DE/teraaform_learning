locals {
  deployment_name = "${var.project_name}-${var.environment}"

  mandatory_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Project     = var.project_name
  }

  common_tags = merge(var.additional_tags, local.mandatory_tags)

  public_service_names = sort([
    for name, service in var.service_tiers : name
    if service.public
  ])

  private_service_names = sort([
    for name, service in var.service_tiers : name
    if !service.public
  ])

  total_replicas = sum([
    for service in values(var.service_tiers) : service.replicas
  ])
}

resource "terraform_data" "service" {
  for_each = var.service_tiers

  input = {
    name       = each.key
    identifier = "${local.deployment_name}-${each.key}"
    port       = each.value.port
    replicas   = each.value.replicas
    public     = each.value.public
    tags       = local.common_tags
  }

  lifecycle {
    precondition {
      condition     = var.environment == "prod" || each.value.replicas <= 5
      error_message = "Non-production service tiers are limited to five replicas for cost safety."
    }
  }
}

resource "terraform_data" "deployment" {
  input = {
    name             = local.deployment_name
    environment      = var.environment
    service_count    = length(terraform_data.service)
    total_replicas   = local.total_replicas
    public_services  = local.public_service_names
    private_services = local.private_service_names
    tags             = local.common_tags
  }
}

check "private_service_exists" {
  assert {
    condition     = length(local.private_service_names) > 0
    error_message = "At least one private service tier is required to model a protected backend."
  }
}

check "mandatory_tags_cannot_be_overridden" {
  assert {
    condition = alltrue([
      local.common_tags.Environment == var.environment,
      local.common_tags.ManagedBy == "Terraform",
      local.common_tags.Owner == var.owner,
      local.common_tags.Project == var.project_name,
    ])
    error_message = "Mandatory tags must take precedence over additional_tags."
  }
}
