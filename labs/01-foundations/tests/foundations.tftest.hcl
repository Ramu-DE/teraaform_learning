run "default_contract_plan" {
  command = plan

  variables {
    project_name = "checkout"
    owner        = "platform-team"
  }

  assert {
    condition     = output.public_service_names == tolist(["frontend"])
    error_message = "Only frontend should be public in the default contract."
  }

  assert {
    condition     = output.private_service_names == tolist(["api", "worker"])
    error_message = "API and worker should be private in sorted order."
  }

  assert {
    condition     = output.common_tags.ManagedBy == "Terraform"
    error_message = "ManagedBy must be enforced as Terraform."
  }
}

run "custom_contract_apply" {
  command = apply

  variables {
    project_name = "orders"
    environment  = "stage"
    owner        = "orders-team"

    service_tiers = {
      gateway = {
        port     = 443
        replicas = 2
        public   = true
      }
      backend = {
        port     = 8080
        replicas = 3
        public   = false
      }
    }

    additional_tags = {
      CostCenter = "learning"
      ManagedBy  = "manual"
    }
  }

  assert {
    condition     = output.deployment_name == "orders-stage"
    error_message = "The deployment name must combine project and environment."
  }

  assert {
    condition     = output.total_replicas == 5
    error_message = "The total replica calculation should equal five."
  }

  assert {
    condition     = output.service_configurations.backend.identifier == "orders-stage-backend"
    error_message = "for_each should create a stable backend configuration."
  }

  assert {
    condition     = output.common_tags.ManagedBy == "Terraform" && output.common_tags.CostCenter == "learning"
    error_message = "Mandatory tags must override caller values while preserving additional tags."
  }
}

run "reject_invalid_environment" {
  command = plan

  variables {
    project_name = "checkout"
    environment  = "qa"
    owner        = "platform-team"
  }

  expect_failures = [var.environment]
}

run "reject_invalid_project_name" {
  command = plan

  variables {
    project_name = "Bad_Name"
    owner        = "platform-team"
  }

  expect_failures = [var.project_name]
}

run "reject_insecure_public_port" {
  command = plan

  variables {
    project_name = "checkout"
    owner        = "platform-team"

    service_tiers = {
      frontend = {
        port     = 80
        replicas = 1
        public   = true
      }
      api = {
        port     = 8080
        replicas = 1
        public   = false
      }
    }
  }

  expect_failures = [var.service_tiers]
}
