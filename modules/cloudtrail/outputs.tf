output "trail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.this.arn
}

output "log_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.trail.id
}
