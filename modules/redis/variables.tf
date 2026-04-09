variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect"
  type        = list(string)
}

variable "node_type" {
  description = "ElastiCache node type (cache.t3.micro for free tier)"
  type        = string
  default     = "cache.t3.micro"
}
