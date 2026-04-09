output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.node.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller IRSA role"
  value       = aws_iam_role.alb_controller.arn
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets IRSA role"
  value       = aws_iam_role.external_secrets.arn
}
