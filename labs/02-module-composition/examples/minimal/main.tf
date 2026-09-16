module "service" {
  source = "../../modules/service"

  deployment_name = "example-dev"
  environment     = "dev"
  service_name    = "api"
  service = {
    port       = 8080
    replicas   = 1
    exposure   = "private"
    route_path = null
  }
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "learner"
    Project     = "example"
  }
}
