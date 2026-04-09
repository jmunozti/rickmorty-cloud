variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "db_password" {
  description = "RDS master password (pass via TF_VAR_db_password or tfvars)"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email for SOC 2 security alerts (pass via TF_VAR_alert_email)"
  type        = string
  default     = ""
}
