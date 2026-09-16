variable "project_name" {
  description = "Project represented by the provider-free workload state."
  type        = string
  default     = "state-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.project_name))
    error_message = "project_name must be 3-24 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "generation" {
  description = "Intentional state generation used to create and inspect S3 object versions."
  type        = number
  default     = 1

  validation {
    condition     = var.generation >= 1 && var.generation == floor(var.generation)
    error_message = "generation must be a positive integer."
  }
}

variable "components" {
  description = "Stable provider-free workload components stored in state."
  type = map(object({
    role     = string
    replicas = number
  }))

  default = {
    frontend = {
      role     = "edge"
      replicas = 2
    }
    api = {
      role     = "backend"
      replicas = 2
    }
    worker = {
      role     = "async"
      replicas = 1
    }
  }

  validation {
    condition = length(var.components) > 0 && alltrue([
      for name, component in var.components :
      can(regex("^[a-z][a-z0-9-]{1,19}$", name)) &&
      length(trimspace(component.role)) >= 2 &&
      component.replicas >= 1 && component.replicas <= 10
    ])
    error_message = "components must be non-empty with stable lowercase names, non-empty roles, and 1-10 replicas."
  }
}

variable "lock_probe_generation" {
  description = "Change this value with -replace to create a lab-only operation that holds the state lock."
  type        = number
  default     = 1
}

variable "lock_hold_seconds" {
  description = "Lab-only local sleep duration used to demonstrate lock contention; keep zero outside the drill."
  type        = number
  default     = 0

  validation {
    condition     = var.lock_hold_seconds >= 0 && var.lock_hold_seconds <= 60 && var.lock_hold_seconds == floor(var.lock_hold_seconds)
    error_message = "lock_hold_seconds must be an integer from 0 through 60."
  }
}
