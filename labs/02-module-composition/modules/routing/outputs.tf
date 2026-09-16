output "routes_by_service" {
  description = "Route contracts keyed by stable service name."
  value = {
    for name, route in terraform_data.route :
    name => route.input
  }
}

output "summary" {
  description = "Routing summary proving how many service contracts were consumed."
  value       = terraform_data.table.input
}
