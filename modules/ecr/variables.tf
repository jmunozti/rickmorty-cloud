variable "name" {
  description = "Name prefix for repositories"
  type        = string
}

variable "repository_names" {
  description = "List of repository names to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}
