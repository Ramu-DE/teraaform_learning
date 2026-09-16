run "default_composition_plan" {
  command = plan

  variables {
    project_name = "checkout"
    owner        = "platform-team"
  }

  assert {
    condition     = toset(keys(output.service_contracts)) == toset(["api", "frontend", "worker"])
    error_message = "The root must instantiate one service module per catalog key."
  }

  assert {
    condition     = toset(keys(output.routes_by_service)) == toset(["frontend"])
    error_message = "Only the public frontend service should be routed."
  }

  assert {
    condition     = output.routes_by_service.frontend.path == "/"
    error_message = "The frontend route should preserve its service contract path."
  }

  assert {
    condition     = output.composition_summary.service_count == 3 && output.composition_summary.route_count == 1
    error_message = "Routing must consume three contracts and create one public route."
  }

  assert {
    condition     = output.service_contracts.api.endpoint == "http://checkout-dev-api.internal.invalid:8080"
    error_message = "The service module must normalize a private API endpoint."
  }
}

run "custom_composition_apply" {
  command = apply

  variables {
    project_name = "catalog"
    environment  = "stage"
    owner        = "catalog-team"

    services = {
      storefront = {
        port       = 443
        replicas   = 3
        exposure   = "public"
        route_path = "/"
      }
      admin = {
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/admin"
      }
      backend = {
        port       = 8080
        replicas   = 2
        exposure   = "private"
        route_path = null
      }
    }

    additional_tags = {
      CostCenter = "learning"
      ManagedBy  = "manual"
    }
  }

  assert {
    condition     = output.deployment_name == "catalog-stage"
    error_message = "The root must own the shared deployment name."
  }

  assert {
    condition     = output.composition_summary.route_count == 2
    error_message = "Both public service contracts should become routes."
  }

  assert {
    condition     = output.routes_by_service.admin.target == "catalog-stage-admin"
    error_message = "Routing must consume the identifier exported by the admin service module."
  }

  assert {
    condition     = output.common_tags.ManagedBy == "Terraform" && output.common_tags.CostCenter == "learning"
    error_message = "Root-owned mandatory tags must override caller values."
  }
}

run "reject_duplicate_public_routes" {
  command = plan

  variables {
    project_name = "checkout"
    owner        = "platform-team"

    services = {
      frontend = {
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/"
      }
      admin = {
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/"
      }
    }
  }

  expect_failures = [var.services]
}

run "reject_public_http_service" {
  command = plan

  variables {
    project_name = "checkout"
    owner        = "platform-team"

    services = {
      frontend = {
        port       = 80
        replicas   = 1
        exposure   = "public"
        route_path = "/"
      }
    }
  }

  expect_failures = [var.services]
}
