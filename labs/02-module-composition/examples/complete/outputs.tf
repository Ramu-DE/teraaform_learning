output "service_contracts" {
  description = "Contracts exported by all service module instances."
  value = {
    for name, service_module in module.service :
    name => service_module.contract
  }
}

output "routes" {
  description = "Routes built from public service contracts."
  value       = module.routing.routes_by_service
}

output "summary" {
  description = "Complete example composition summary."
  value       = module.routing.summary
}
