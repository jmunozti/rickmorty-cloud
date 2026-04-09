variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for Aurora"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to Aurora"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "min_capacity" {
  description = "Aurora Serverless v2 minimum ACUs (0.5 = near-zero cost when idle)"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Aurora Serverless v2 maximum ACUs"
  type        = number
  default     = 4
}

variable "replica_count" {
  description = "Number of read replicas (0 for dev, 1+ for prod HA)"
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_tag" {
  description = "AWS Backup tag (daily or weekly)"
  type        = string
  default     = "daily"
}
