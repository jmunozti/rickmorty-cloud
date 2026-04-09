variable "name" {
  description = "Name prefix"
  type        = string
}

variable "alert_email" {
  description = "Email for security alerts (empty to skip)"
  type        = string
  default     = ""
}
