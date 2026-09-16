locals {
  identifier = "${var.deployment_name}-${var.service_name}"
  is_public  = var.service.exposure == "public"
  hostname   = "${local.identifier}.${local.is_public ? "example.invalid" : "internal.invalid"}"
  endpoint   = local.is_public ? "https://${local.hostname}" : "http://${local.hostname}:${var.service.port}"
}

resource "terraform_data" "this" {
  input = {
    name       = var.service_name
    identifier = local.identifier
    endpoint   = local.endpoint
    port       = var.service.port
    replicas   = var.service.replicas
    exposure   = var.service.exposure
    route_path = local.is_public ? var.service.route_path : null
    tags       = var.tags
  }

  lifecycle {
    precondition {
      condition     = var.environment == "prod" || var.service.replicas <= 5
      error_message = "Non-production services are limited to five replicas for cost safety."
    }
  }
}
