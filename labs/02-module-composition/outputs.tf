output "deployment_name" {
  description = "Deterministic project and environment identifier."
  value       = local.deployment_name
}

output "service_contracts" {
  description = "Typed contracts exported by all service child-module instances."
  value = {
    for name, service_module in module.service :
    name => service_module.contract
  }
}

output "routes_by_service" {
  description = "Public routes built by the routing child module."
  value       = module.routing.routes_by_service
}

output "composition_summary" {
  description = "Summary proving the routing module consumed service module outputs."
  value       = module.routing.summary
}

output "common_tags" {
  description = "Final root-owned tags passed to every service module instance."
  value       = local.common_tags
}
