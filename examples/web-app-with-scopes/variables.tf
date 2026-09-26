variable "region" {
  description = "AWS region the user pool is created in."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Lowercase Cognito user-pool name."
  type        = string
}

variable "callback_urls" {
  description = "HTTPS callback URLs the browser SPA client redirects to after sign-in."
  type        = set(string)
}

variable "logout_urls" {
  description = "HTTPS logout URLs the browser SPA client redirects to after sign-out."
  type        = set(string)
}
