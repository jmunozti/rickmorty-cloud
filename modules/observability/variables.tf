variable "name" {
  description = "Name prefix"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (empty to skip)"
  type        = string
  default     = ""
}
