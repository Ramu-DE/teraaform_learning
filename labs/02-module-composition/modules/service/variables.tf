variable "deployment_name" {
  description = "Root-owned deployment identifier used as the service name prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,47}$", var.deployment_name))
    error_message = "deployment_name must be 3-48 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "environment" {
  description = "Deployment lifecycle environment used by module safety checks."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage, or prod."
  }
}

variable "service_name" {
  description = "Stable logical key for this service instance."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.service_name))
    error_message = "service_name must be 2-20 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "service" {
  description = "Service behavior consumed and normalized by this module."
  type = object({
    port       = number
    replicas   = number
    exposure   = string
    route_path = optional(string)
  })

  validation {
    condition = (
      var.service.port >= 1 && var.service.port <= 65535 &&
      var.service.replicas >= 1 && var.service.replicas <= 10 &&
      contains(["public", "private"], var.service.exposure) &&
      (
        var.service.exposure == "private" ||
        (
          var.service.port == 443 &&
          var.service.route_path != null &&
          can(regex("^/[a-z0-9/_-]*$", var.service.route_path))
        )
      )
    )
    error_message = "service must use a valid port, 1-10 replicas, and public/private exposure; public services require port 443 and a lowercase absolute route_path."
  }
}

variable "tags" {
  description = "Root-owned metadata attached to the normalized service contract."
  type        = map(string)
}
