locals {
  deployment_name = "${var.project_name}-${var.environment}"

  mandatory_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Project     = var.project_name
  }

  common_tags = merge(var.additional_tags, local.mandatory_tags)
}

module "service" {
  source   = "./modules/service"
  for_each = var.services

  deployment_name = local.deployment_name
  environment     = var.environment
  service_name    = each.key
  service         = each.value
  tags            = local.common_tags
}

module "routing" {
  source = "./modules/routing"

  deployment_name = local.deployment_name
  service_contracts = {
    for name, service_module in module.service :
    name => service_module.contract
  }
}
