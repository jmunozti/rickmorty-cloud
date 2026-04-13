# ADR-001: Use Amazon EKS over ECS/Fargate


## Context
We need to orchestrate containers on AWS with the following requirements:
- Fine-grained control over the data plane for security policies (NetworkPolicies, PodSecurity, Kyverno/OPA)
- Multi-cloud portability in the future (avoid strong vendor lock-in)
- Compatibility with the CNCF ecosystem (Helm, ArgoCD, Kustomize, Prometheus)

## Decision
We will use **Amazon EKS** as our container orchestration platform.

## Alternatives Considered
| Option | Pros | Cons | Why Not Selected |
|--------|------|------|-----------------|
| ECS/Fargate | Less operational overhead, serverless, lower initial cost | Strong vendor lock-in, limited support for native K8s policies, reduced portability | Does not meet portability or fine-grained security requirements |
| EKS self-managed | Maximum control, no control plane cost | High operational complexity, manual control plane maintenance | Managed EKS offers the ideal balance between control and operational burden |
| **EKS managed (selected)** | Data plane control + AWS-managed control plane + native K8s ecosystem | ~$73/month per control plane, Kubernetes learning curve |  Best balance for our technical and business requirements |

## Consequences
### Positive
- **Portability**: K8s manifests are compatible with other clusters (on-prem, GCP, Azure)
- **Security**: Enables NetworkPolicies, PodSecurity, Kyverno, OPA/Gatekeeper
- **Ecosystem**: Native support for Helm, Kustomize, ArgoCD, Prometheus, Grafana
- **Talent**: Kubernetes skills are transferable and widely in demand

### Negative
- Higher initial cost than Fargate for small workloads (~$73/month per control plane)
- Requires Kubernetes knowledge in the team (mitigated via documentation and ADRs)

### Neutral
- Control plane is managed by AWS, but worker nodes remain our operational responsibility

## Date
2026-04-10

## Authors
@jmunozti