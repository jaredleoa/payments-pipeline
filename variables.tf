variable "project_name" {
  description = "Base name for all resources in the Payments Event Pipeline"
  type        = string
  default     = "payments-event-pipeline"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-1"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days for Lambda logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources"
  type        = map(string)
  default     = {}
}
