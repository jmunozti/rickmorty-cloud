variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for the ALB controller"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "1.7.1"
}
