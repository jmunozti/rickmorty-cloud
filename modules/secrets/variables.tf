variable "name" {
  description = "Name prefix for secrets"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ExternalSecret resources"
  type        = string
  default     = "default"
}

variable "secrets" {
  description = "Map of secret name to key-value pairs"
  type        = map(map(string))
  default     = {}
}

variable "recovery_window" {
  description = "Recovery window in days for secret deletion"
  type        = number
  default     = 7
}
