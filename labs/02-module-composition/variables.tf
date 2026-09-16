variable "project_name" {
  description = "Short project name used in deterministic service identifiers."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.project_name))
    error_message = "project_name must be 3-24 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "environment" {
  description = "Deployment lifecycle environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage, or prod."
  }
}

variable "owner" {
  description = "Team or person accountable for this deployment."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) >= 3
    error_message = "owner must contain at least three non-whitespace characters."
  }
}

variable "services" {
  description = "Service catalog composed by the root module."
  type = map(object({
    port       = number
    replicas   = number
    exposure   = string
    route_path = optional(string)
  }))

  default = {
    frontend = {
      port       = 443
      replicas   = 2
      exposure   = "public"
      route_path = "/"
    }
    api = {
      port       = 8080
      replicas   = 2
      exposure   = "private"
      route_path = null
    }
    worker = {
      port       = 9000
      replicas   = 1
      exposure   = "private"
      route_path = null
    }
  }

  validation {
    condition = length(var.services) > 0 && alltrue([
      for name, service in var.services :
      can(regex("^[a-z][a-z0-9-]{1,19}$", name)) &&
      service.port >= 1 && service.port <= 65535 &&
      service.replicas >= 1 && service.replicas <= 10 &&
      contains(["public", "private"], service.exposure) &&
      (
        service.exposure == "private" ||
        (
          service.port == 443 &&
          service.route_path != null &&
          can(regex("^/[a-z0-9/_-]*$", service.route_path))
        )
      )
    ])
    error_message = "services must be non-empty and valid; public services require port 443 and a lowercase absolute route_path."
  }

  validation {
    condition = length(distinct([
      for service in values(var.services) : service.route_path
      if service.exposure == "public"
      ])) == length([
      for service in values(var.services) : service.route_path
      if service.exposure == "public"
    ])
    error_message = "Public service route_path values must be unique."
  }
}

variable "additional_tags" {
  description = "Extra metadata merged with mandatory root tags; mandatory values take precedence."
  type        = map(string)
  default     = {}
}
