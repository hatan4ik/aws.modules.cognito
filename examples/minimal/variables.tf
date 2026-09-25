variable "region" {
  description = "AWS region the user pool is created in."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Lowercase Cognito user-pool name."
  type        = string
}
