run "default_state_plan" {
  command = apply

  assert {
    condition     = toset(keys(output.component_contracts)) == toset(["api", "frontend", "worker"])
    error_message = "Default state must contain all three stable component keys."
  }

  assert {
    condition     = output.state_summary.total_replicas == 5
    error_message = "Default workload should total five replicas."
  }
}

run "generation_two_apply" {
  command = apply

  variables {
    generation = 2
  }

  assert {
    condition     = output.generation == 2
    error_message = "The applied state must record generation two."
  }

  assert {
    condition     = output.component_contracts.api.generation == 2
    error_message = "Component contracts must carry the requested state generation."
  }
}

run "custom_components_plan" {
  command = apply

  variables {
    components = {
      gateway = {
        role     = "edge"
        replicas = 1
      }
      backend = {
        role     = "application"
        replicas = 3
      }
    }
  }

  assert {
    condition     = output.state_summary.total_replicas == 4
    error_message = "Custom component replicas should sum to four."
  }
}

run "reject_excessive_lock_hold" {
  command = plan

  variables {
    lock_hold_seconds = 61
  }

  expect_failures = [var.lock_hold_seconds]
}
