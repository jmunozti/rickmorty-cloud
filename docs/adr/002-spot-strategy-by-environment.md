# ADR-002: Spot Instances in Dev, On-Demand in Prod


## Context
Optimize AWS infrastructure costs without sacrificing production reliability:
- **Dev environment**: interruption-tolerant workloads, testing, development
- **Prod environment**: high availability, critical SLA, end-user traffic

## Decision
- **Dev**: Use **Spot Instances** with `t3.small` (1-4 nodes)
- **Prod**: Use **On-Demand Instances** with `t3.large`/`t3.xlarge` (3-10 nodes, multi-AZ)

## Alternatives Considered
| Option | Pros | Cons | Why Not Selected |
|--------|------|------|-----------------|
| Spot in both environments | Maximum cost savings (~70-90%) | Risk of interruption in prod, unsuitable for critical workloads | Does not meet production availability requirements |
| On-Demand in both environments | Maximum stability | High cost in dev (~3-4x vs Spot) | Does not optimize resources in non-production environments |
| **Hybrid (selected)** | Significant savings in dev + stability in prod | Dual-management complexity, requires differentiated tagging and monitoring | ✅ Best cost/benefit balance for our use cases |

## Consequences
### Positive
- Estimated ~70% compute cost savings in dev environment
- Guaranteed stability in prod with On-Demand + multi-AZ deployment
- Flexibility: strategy is parameterized via Terraform variables (`capacity_type`), enabling environment-specific adjustments without code changes

### Negative
- Requires additional monitoring to detect Spot interruptions in dev
- Documentation must clarify environment differences for team awareness

### Neutral
- Configuration is managed via Terraform variables, with no impact on application logic

## Date
2026-04-10

## Authors
@jmunozti