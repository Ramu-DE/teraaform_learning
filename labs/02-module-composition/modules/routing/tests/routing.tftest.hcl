run "mixed_contracts_plan" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    service_contracts = {
      frontend = {
        name       = "frontend"
        identifier = "checkout-dev-frontend"
        endpoint   = "https://checkout-dev-frontend.example.invalid"
        port       = 443
        replicas   = 2
        exposure   = "public"
        route_path = "/"
        tags       = {}
      }
      api = {
        name       = "api"
        identifier = "checkout-dev-api"
        endpoint   = "http://checkout-dev-api.internal.invalid:8080"
        port       = 8080
        replicas   = 2
        exposure   = "private"
        route_path = null
        tags       = {}
      }
    }
  }

  assert {
    condition     = toset(keys(output.routes_by_service)) == toset(["frontend"])
    error_message = "Routing must filter out private service contracts."
  }

  assert {
    condition     = output.summary.service_count == 2 && output.summary.route_count == 1
    error_message = "The summary must distinguish consumed services from public routes."
  }
}

run "public_routes_apply" {
  command = apply

  variables {
    deployment_name = "portal-stage"
    service_contracts = {
      portal = {
        name       = "portal"
        identifier = "portal-stage-portal"
        endpoint   = "https://portal-stage-portal.example.invalid"
        port       = 443
        replicas   = 2
        exposure   = "public"
        route_path = "/portal"
        tags       = {}
      }
    }
  }

  assert {
    condition     = output.routes_by_service.portal.path == "/portal"
    error_message = "The route must retain the child service contract path."
  }
}

run "reject_duplicate_paths" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    service_contracts = {
      frontend = {
        name       = "frontend"
        identifier = "checkout-dev-frontend"
        endpoint   = "https://checkout-dev-frontend.example.invalid"
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/"
        tags       = {}
      }
      admin = {
        name       = "admin"
        identifier = "checkout-dev-admin"
        endpoint   = "https://checkout-dev-admin.example.invalid"
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/"
        tags       = {}
      }
    }
  }

  expect_failures = [var.service_contracts]
}

run "reject_non_https_public_contract" {
  command = plan

  variables {
    deployment_name = "checkout-dev"
    service_contracts = {
      frontend = {
        name       = "frontend"
        identifier = "checkout-dev-frontend"
        endpoint   = "http://checkout-dev-frontend.example.invalid"
        port       = 443
        replicas   = 1
        exposure   = "public"
        route_path = "/"
        tags       = {}
      }
    }
  }

  expect_failures = [var.service_contracts]
}
