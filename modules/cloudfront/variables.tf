variable "name" {
  description = "Name prefix"
  type        = string
}

variable "s3_bucket_domain" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "waf_acl_arn" {
  description = "WAF Web ACL ARN (empty to skip)"
  type        = string
  default     = ""
}
