run "private_service_plan" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    environment     = "dev"
    service_name    = "api"
    service = {
      port       = 8080
      replicas   = 2
      exposure   = "private"
      route_path = null
    }
    tags = {
      ManagedBy = "Terraform"
    }
  }

  assert {
    condition     = output.contract.identifier == "checkout-dev-api"
    error_message = "The service identifier must combine deployment and service names."
  }

  assert {
    condition     = output.contract.endpoint == "http://checkout-dev-api.internal.invalid:8080"
    error_message = "A private service must expose its modeled internal endpoint."
  }

  assert {
    condition     = output.contract.route_path == null
    error_message = "Private service contracts must not export a public route path."
  }
}

run "public_service_apply" {
  command = apply

  variables {
    deployment_name = "checkout-prod"
    environment     = "prod"
    service_name    = "frontend"
    service = {
      port       = 443
      replicas   = 6
      exposure   = "public"
      route_path = "/"
    }
    tags = {
      ManagedBy = "Terraform"
    }
  }

  assert {
    condition     = output.contract.endpoint == "https://checkout-prod-frontend.example.invalid"
    error_message = "A public service must export an HTTPS endpoint."
  }
}

run "reject_invalid_public_service" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    environment     = "dev"
    service_name    = "frontend"
    service = {
      port       = 80
      replicas   = 1
      exposure   = "public"
      route_path = "/"
    }
    tags = {}
  }

  expect_failures = [var.service]
}

run "reject_excess_nonproduction_scale" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    environment     = "dev"
    service_name    = "worker"
    service = {
      port       = 9000
      replicas   = 6
      exposure   = "private"
      route_path = null
    }
    tags = {}
  }

  expect_failures = [terraform_data.this]
}
