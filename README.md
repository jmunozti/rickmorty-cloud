# rickmorty-cloud

> Rick and Morty Explorer on AWS — 12 Terraform modules, EKS, RDS, Redis, S3, CloudFront, WAF, and more

**Status: Infrastructure code complete. Pending AWS deployment and live testing.**

All 12 Terraform modules are written, validated (`terraform validate`), and security-scanned. The app (FastAPI + Next.js) is tested locally with 13 passing tests. AWS deployment is next.

A complete cloud platform that deploys a Rick and Morty Explorer app (FastAPI + Next.js) on AWS EKS, with every production service you'd expect: database, cache, CDN, firewall, audit trail, monitoring, and secrets management.

## Why This Project

This is how real companies run on AWS. Every module follows AWS Well-Architected best practices:

- **12 Terraform modules** — VPC, EKS, IAM, ALB, RDS, Redis, S3, CloudFront, WAF, CloudTrail, ECR, Observability
- **Remote state** — S3 with KMS encryption + DynamoDB locking
- **Multi-environment** — Dev (spot, 2 AZs, $minimal) vs Prod (on-demand, 3 AZs, HA)
- **Security** — WAF, KMS encryption, IRSA, VPC flow logs, CloudTrail, non-root containers, ECR scan-on-push
- **Observability** — CloudWatch dashboards + alarms, X-Ray tracing, Prometheus
- **Cost optimization** — Spot instances in dev, S3 lifecycle policies, ElastiCache free tier

## Architecture

![Architecture](docs/architecture.png)

## The App

**Rick and Morty Explorer** — browse characters from the Rick and Morty API, search, and save favorites to PostgreSQL. Images cached in Redis, served via CloudFront.

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 16 + TypeScript + Tailwind CSS + shadcn/ui + pnpm |
| Backend | FastAPI + Python 3.12 |
| Database | RDS PostgreSQL 16 (free tier) |
| Cache | ElastiCache Redis 7.1 (free tier) |
| Storage | S3 + CloudFront CDN |

## AWS Services Used

| Service | Module | Purpose |
|---------|--------|---------|
| **EKS** | `modules/eks` | Kubernetes cluster + managed node groups |
| **VPC** | `modules/vpc` | Networking: public/private subnets, NAT, flow logs |
| **IAM** | `modules/iam` | Cluster/node roles, IRSA for ALB + External Secrets |
| **ALB** | `modules/alb` | Load Balancer Controller via Helm |
| **RDS** | `modules/rds` | PostgreSQL 16, encrypted, automated backups |
| **ElastiCache** | `modules/redis` | Redis 7.1 cache (free tier) |
| **S3** | `modules/s3` | Asset storage with lifecycle policies + versioning |
| **CloudFront** | `modules/cloudfront` | CDN with OAC for S3, HTTPS redirect |
| **WAF** | `modules/waf` | Managed rules + rate limiting on ALB |
| **CloudTrail** | `modules/cloudtrail` | API audit trail to S3 |
| **ECR** | `modules/ecr` | Container registry, scan-on-push, immutable tags |
| **Secrets Manager** | `modules/secrets` | App secrets + External Secrets Operator manifests |
| **CloudWatch** | `modules/observability` | Dashboard, alarms (CPU, 5xx), X-Ray tracing |

## Dev vs Prod

| | Dev | Prod |
|--|-----|------|
| AZs | 2 | 3 |
| Nodes | t3.medium SPOT (1-4) | t3.large ON_DEMAND (3-10) |
| RDS | db.t3.micro, single AZ | db.t3.medium, multi AZ |
| API endpoint | Public | Private |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |

## Prerequisites

- [Docker](https://www.docker.com/) — that's it. Everything else runs inside the deploy container.
- An AWS account with an IAM user that has permissions for: EKS, EC2, VPC, RDS, ElastiCache, S3, CloudFront, WAF, CloudTrail, Secrets Manager, ECR, CloudWatch, IAM, DynamoDB, KMS.

## Usage

The only prerequisite is **Docker**. Everything else (Terraform, kubectl, Helm, AWS CLI) runs inside a deploy container.

### 1. Set your AWS credentials

```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_DEFAULT_REGION=us-east-1
```

### 2. Deploy everything (one command)

```bash
make deploy
```

This single command:
1. Builds a Docker container with all prerequisites
2. Creates the S3 backend for Terraform state
3. Deploys all 12 AWS services (VPC, EKS, RDS, Redis, S3, CloudFront, WAF, etc.)
4. Generates a random DB password (or uses `TF_VAR_db_password` if set)
5. Builds and pushes app images to ECR (auto-login, no manual steps)
6. Configures kubectl and shows cluster status

### 3. Check status

```bash
make status
```

### 4. Destroy when done

```bash
make destroy
```

### All commands

```bash
make deploy         # Deploy everything to dev (infra + app)
make deploy-prod    # Deploy everything to prod
make infra          # Deploy only infrastructure (no images)
make push           # Build and push images to ECR
make status         # Show cluster status and outputs
make destroy        # Destroy dev environment
make destroy-prod   # Destroy prod environment
make test           # Run API tests locally
make lint           # Lint API code locally
make validate       # Validate Terraform locally
```

## CI/CD

Every push to `main` or `develop` runs 5 parallel jobs:

| Job | What it does |
|-----|-------------|
| lint-test-backend | ruff lint + 13 pytest tests |
| build-backend | Docker build + Trivy CVE scan |
| build-frontend | Docker build + Trivy CVE scan |
| terraform-validate | fmt + init + validate (dev & prod) |
| terraform-security | tfsec + checkov scan all modules |

## Project Structure

```
aws/
├── backend/                     # S3 + DynamoDB remote state
├── modules/
│   ├── vpc/                     # VPC, subnets, NAT, IGW, flow logs
│   ├── eks/                     # EKS, node groups, OIDC, KMS
│   ├── iam/                     # Roles, IRSA (ALB, External Secrets)
│   ├── alb/                     # AWS Load Balancer Controller
│   ├── rds/                     # PostgreSQL 16, encrypted, backups
│   ├── redis/                   # ElastiCache Redis 7.1
│   ├── s3/                      # Asset bucket + lifecycle + IRSA policy
│   ├── cloudfront/              # CDN + OAC + S3 policy
│   ├── waf/                     # Managed rules + rate limiting
│   ├── cloudtrail/              # API audit to S3
│   ├── ecr/                     # Container registry, scan-on-push
│   ├── secrets/                 # Secrets Manager + External Secrets
│   └── observability/           # CloudWatch dashboard + alarms + X-Ray
├── environments/
│   ├── dev/                     # Spot, 2 AZs, minimal
│   └── prod/                    # On-demand, 3 AZs, HA
├── app/
│   ├── backend/                 # FastAPI (Rick and Morty API + favorites)
│   └── frontend/                # Next.js 16 + shadcn/ui
├── .github/workflows/ci.yml
├── Makefile
└── README.md
```

## License

MIT
