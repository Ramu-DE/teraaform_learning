variable "project_name" {
  description = "Short project name used to build deterministic identifiers."
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
  description = "Team or person accountable for the configuration."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) >= 3
    error_message = "owner must contain at least three non-whitespace characters."
  }
}

variable "service_tiers" {
  description = "Logical service tiers used to practice object types, maps, validation, and for_each."
  type = map(object({
    port     = number
    replicas = number
    public   = bool
  }))

  default = {
    frontend = {
      port     = 443
      replicas = 2
      public   = true
    }
    api = {
      port     = 8080
      replicas = 2
      public   = false
    }
    worker = {
      port     = 9000
      replicas = 1
      public   = false
    }
  }

  validation {
    condition = length(var.service_tiers) > 0 && alltrue([
      for name, service in var.service_tiers :
      can(regex("^[a-z][a-z0-9-]{1,19}$", name)) &&
      service.port >= 1 && service.port <= 65535 &&
      service.replicas >= 1 && service.replicas <= 10 &&
      (!service.public || service.port == 443)
    ])
    error_message = "service_tiers must be non-empty; names must be 2-20 lowercase characters; ports must be 1-65535; replicas must be 1-10; public services must use port 443."
  }
}

variable "additional_tags" {
  description = "Extra metadata merged with mandatory tags; mandatory values take precedence."
  type        = map(string)
  default     = {}
}
