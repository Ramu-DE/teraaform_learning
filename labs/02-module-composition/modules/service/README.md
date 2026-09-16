# Service Child Module

Normalizes one logical service into a stable contract that sibling modules can consume.

## Inputs

- `deployment_name`: root-owned prefix.
- `environment`: lifecycle context used for safety checks.
- `service_name`: stable logical key.
- `service`: port, replicas, exposure, and optional public route path.
- `tags`: metadata fully owned by the composition root.

## Output contract

`contract` contains `name`, `identifier`, `endpoint`, `port`, `replicas`, `exposure`, normalized `route_path`, and `tags`. Public services require HTTPS modeling on port 443. Private services export an internal endpoint and a null route path.

`resource_id` is intentionally opaque and demonstrates that consumers should prefer the semantic contract rather than implementation-specific IDs.

## Guarantees

- Deterministic identifier and endpoint.
- Public service validation requires port 443 and an absolute lowercase path.
- Nonproduction services cannot exceed five replicas.
- No provider configuration and no hidden network/routing dependency.

## Non-goals

This learning module creates no compute, DNS, load balancer, or network. `.invalid` hostnames cannot resolve publicly. A future AWS service module can preserve the output contract while changing its implementation.

## Test independently

```bash
terraform init -backend=false
terraform validate
terraform test
```

The suite covers a private plan, public apply, invalid public port, and the nonproduction scale precondition.
