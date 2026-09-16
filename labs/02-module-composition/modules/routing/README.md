# Routing Child Module

Consumes service contracts and creates route models only for public services. It demonstrates dependency inversion: routing depends on a typed interface, not on service implementation details.

## Inputs

- `deployment_name`: root-owned deployment identifier.
- `service_contracts`: map of normalized service contract objects.

The variable validates public HTTPS endpoints, port 443, absolute lowercase paths, and unique public paths.

## Outputs

- `routes_by_service`: public routes keyed by stable service name.
- `summary`: number of consumed service contracts, number of routes, and routed service names.

## Guarantees

- Private contracts are filtered out.
- Every produced route targets HTTPS.
- Route resources use service names as stable `for_each` keys.
- The module does not call the service module or configure a provider.

## Non-goals

This module does not create real DNS, certificates, load balancers, or listener rules. It models the contract those future modules will consume.

## Test independently

```bash
terraform init -backend=false
terraform validate
terraform test
```

The suite covers mixed contracts, apply behavior, duplicate paths, and rejection of non-HTTPS public endpoints.
