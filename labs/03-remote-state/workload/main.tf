locals {
  total_replicas = sum([
    for component in values(var.components) : component.replicas
  ])
}

resource "terraform_data" "component" {
  for_each = var.components

  input = {
    name       = each.key
    identifier = "${var.project_name}-${each.key}"
    role       = each.value.role
    replicas   = each.value.replicas
    generation = var.generation
  }
}

# LAB ONLY: local-exec is used solely to hold the Terraform state lock long
# enough for a second process to demonstrate lock contention. It creates no
# infrastructure and must not be copied into production modules.
resource "terraform_data" "lock_probe" {
  input = {
    generation = var.lock_probe_generation
  }

  triggers_replace = [var.lock_probe_generation]

  provisioner "local-exec" {
    command     = "sleep ${var.lock_hold_seconds}"
    interpreter = ["/bin/sh", "-c"]
  }
}

resource "terraform_data" "summary" {
  input = {
    project        = var.project_name
    generation     = var.generation
    component_keys = sort(keys(terraform_data.component))
    total_replicas = local.total_replicas
  }
}
