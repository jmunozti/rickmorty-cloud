output "web_acl_arn" {
  description = "WAF Web ACL ARN (attach to ALB)"
  value       = aws_wafv2_web_acl.this.arn
}
