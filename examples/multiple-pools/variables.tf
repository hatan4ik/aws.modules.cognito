variable "region" {
  description = "AWS region the user pools are created in."
  type        = string
  default     = "us-east-1"
}

variable "pools" {
  description = "User pools to create, keyed by environment. Each entry names the pool and sets its own deletion protection and MFA policy, since a non-production pool is often torn down and does not need the same guardrails as production."
  type = map(object({
    name                = string
    deletion_protection = bool
    mfa_configuration   = string
  }))
}
