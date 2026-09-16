locals {
  services = {
    web = {
      port       = 443
      replicas   = 2
      exposure   = "public"
      route_path = "/"
    }
    api = {
      port       = 8080
      replicas   = 2
      exposure   = "private"
      route_path = null
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "learner"
    Project     = "complete-example"
  }
}

module "service" {
  source   = "../../modules/service"
  for_each = local.services

  deployment_name = "example-dev"
  environment     = "dev"
  service_name    = each.key
  service         = each.value
  tags            = local.tags
}

module "routing" {
  source = "../../modules/routing"

  deployment_name = "example-dev"
  service_contracts = {
    for name, service_module in module.service :
    name => service_module.contract
  }
}
