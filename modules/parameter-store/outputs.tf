output "parameter_arns" {
  description = "Map of parameter name to ARN"
  value       = { for k, v in aws_ssm_parameter.this : k => v.arn }
}

output "read_policy_arn" {
  description = "IAM policy ARN for reading parameters"
  value       = aws_iam_policy.read_params.arn
}
