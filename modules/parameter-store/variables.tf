variable "name" {
  description = "Name prefix (used as path: /{name}/{key})"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "parameters" {
  description = "Map of parameter name to value and description"
  type = map(object({
    value       = string
    description = string
    secure      = optional(bool, false)
  }))
  default = {}
}
