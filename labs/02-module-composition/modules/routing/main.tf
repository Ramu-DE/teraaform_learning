locals {
  public_contracts = {
    for name, contract in var.service_contracts :
    name => contract
    if contract.exposure == "public"
  }
}

resource "terraform_data" "route" {
  for_each = local.public_contracts

  input = {
    service_name = each.key
    path         = each.value.route_path
    target       = each.value.identifier
    endpoint     = each.value.endpoint
  }
}

resource "terraform_data" "table" {
  input = {
    deployment_name = var.deployment_name
    service_count   = length(var.service_contracts)
    route_count     = length(terraform_data.route)
    routed_services = sort(keys(terraform_data.route))
  }
}

check "public_routes_use_https" {
  assert {
    condition = alltrue([
      for route in values(terraform_data.route) :
      startswith(route.input.endpoint, "https://")
    ])
    error_message = "Every public route must target an HTTPS endpoint."
  }
}
