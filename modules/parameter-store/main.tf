# AWS Systems Manager Parameter Store
# Stores non-secret configuration per environment

resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = "/${var.name}/${each.key}"
  description = each.value.description
  type        = each.value.secure ? "SecureString" : "String"
  value       = each.value.value
  tier        = "Standard"

  tags = {
    Name        = "${var.name}-${each.key}"
    Environment = var.environment
  }
}

# IAM policy for pods to read parameters
resource "aws_iam_policy" "read_params" {
  name        = "${var.name}-ssm-read"
  description = "Allow reading SSM parameters for ${var.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = "arn:aws:ssm:*:*:parameter/${var.name}/*"
    }]
  })
}
