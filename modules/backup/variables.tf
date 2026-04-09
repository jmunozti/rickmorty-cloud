variable "name" {
  description = "Name prefix"
  type        = string
}

variable "retention_days" {
  description = "Daily backup retention in days"
  type        = number
  default     = 14
}

variable "weekly_retention_days" {
  description = "Weekly backup retention in days"
  type        = number
  default     = 90
}

variable "cold_storage_after" {
  description = "Move weekly backups to cold storage after N days"
  type        = number
  default     = 30
}
