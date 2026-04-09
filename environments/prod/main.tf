terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  backend "s3" {
    bucket         = "eks-platform-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-platform-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "eks-platform"
      ManagedBy   = "terraform"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}

locals {
  name         = "eks-platform"
  cluster_name = "${local.name}-prod"
}

# --- IAM ---
module "iam" {
  source = "../../modules/iam"
  name   = local.cluster_name
}

# --- VPC ---
module "vpc" {
  source       = "../../modules/vpc"
  name         = local.cluster_name
  vpc_cidr     = var.vpc_cidr
  az_count     = 3
  cluster_name = local.cluster_name
}

# --- EKS ---
module "eks" {
  source           = "../../modules/eks"
  cluster_name     = local.cluster_name
  cluster_version  = "1.29"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn

  node_instance_types = ["t3.large", "t3.xlarge"]
  capacity_type       = "ON_DEMAND"
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 10
  public_access       = false
}

# --- IAM IRSA ---
module "iam_irsa" {
  source            = "../../modules/iam"
  name              = local.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

# --- ALB Controller ---
module "alb" {
  source       = "../../modules/alb"
  cluster_name = local.cluster_name
  role_arn     = module.iam_irsa.alb_controller_role_arn
  vpc_id       = module.vpc.vpc_id
  region       = var.region
}

# --- RDS PostgreSQL (prod: multi-AZ) ---
module "rds" {
  source                     = "../../modules/rds"
  name                       = local.cluster_name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.t3.medium"
  db_name                    = "appdb"
  db_username                = "dbadmin"
  db_password                = var.db_password
  multi_az                   = true
  skip_final_snapshot        = false
  backup_retention_days      = 14
}

# --- Redis ---
module "redis" {
  source                     = "../../modules/redis"
  name                       = local.cluster_name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  node_type                  = "cache.t3.small"
}

# --- ECR ---
module "ecr" {
  source           = "../../modules/ecr"
  name             = local.cluster_name
  repository_names = ["backend", "frontend"]
}

# --- S3 (app assets) ---
module "s3" {
  source      = "../../modules/s3"
  bucket_name = "${local.cluster_name}-assets"
}

# --- WAF ---
module "waf" {
  source     = "../../modules/waf"
  name       = local.cluster_name
  rate_limit = 5000
}

# --- CloudFront ---
module "cloudfront" {
  source           = "../../modules/cloudfront"
  name             = local.cluster_name
  s3_bucket_domain = module.s3.bucket_domain
  s3_bucket_name   = module.s3.bucket_name
  s3_bucket_arn    = module.s3.bucket_arn
  waf_acl_arn      = module.waf.web_acl_arn
}

# --- CloudTrail ---
module "cloudtrail" {
  source = "../../modules/cloudtrail"
  name   = local.cluster_name
}

# --- Observability (CloudWatch + X-Ray) ---
module "observability" {
  source       = "../../modules/observability"
  name         = local.cluster_name
  region       = var.region
  cluster_name = local.cluster_name
}

# --- Secrets Manager ---
module "secrets" {
  source    = "../../modules/secrets"
  name      = local.cluster_name
  region    = var.region
  namespace = "default"

  secrets = {
    "app-db" = {
      DB_HOST     = module.rds.address
      DB_USER     = "dbadmin"
      DB_PASSWORD = var.db_password
      DB_NAME     = "appdb"
    }
    "app-redis" = {
      REDIS_HOST = module.redis.endpoint
      REDIS_PORT = tostring(module.redis.port)
    }
  }
}
