variable "deployment_name" {
  description = "Root-owned deployment identifier represented by this route table."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,47}$", var.deployment_name))
    error_message = "deployment_name must be 3-48 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "service_contracts" {
  description = "Contracts exported by service module instances; only public services become routes."
  type = map(object({
    name       = string
    identifier = string
    endpoint   = string
    port       = number
    replicas   = number
    exposure   = string
    route_path = optional(string)
    tags       = map(string)
  }))

  validation {
    condition = alltrue([
      for contract in values(var.service_contracts) :
      contains(["public", "private"], contract.exposure) &&
      (
        contract.exposure == "private" ||
        (
          contract.port == 443 &&
          contract.route_path != null &&
          can(regex("^/[a-z0-9/_-]*$", contract.route_path)) &&
          startswith(contract.endpoint, "https://")
        )
      )
    ])
    error_message = "Public service contracts require port 443, a lowercase absolute route_path, and an HTTPS endpoint."
  }

  validation {
    condition = length(distinct([
      for contract in values(var.service_contracts) : contract.route_path
      if contract.exposure == "public"
      ])) == length([
      for contract in values(var.service_contracts) : contract.route_path
      if contract.exposure == "public"
    ])
    error_message = "Public service contracts must use unique route paths."
  }
}
