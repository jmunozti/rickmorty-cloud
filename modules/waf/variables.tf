variable "name" {
  description = "Name prefix"
  type        = string
}

variable "rate_limit" {
  description = "Max requests per 5-minute period per IP"
  type        = number
  default     = 2000
}
