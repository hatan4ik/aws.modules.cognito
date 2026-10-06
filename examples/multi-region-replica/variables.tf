variable "primary_user_pool_id" {
  description = "Existing eligible primary Cognito user-pool ID."
  type        = string
}

variable "primary_region" {
  description = "Authoritative user-pool Region."
  type        = string
  default     = "us-east-2"
}

variable "secondary_region" {
  description = "Replica Region."
  type        = string
  default     = "us-west-2"
}

variable "feature_plan" {
  description = "Primary pool feature plan."
  type        = string
  default     = "ESSENTIALS"
}

variable "mfa_configuration" {
  description = "Primary pool MFA policy. ACTIVE is blocked for ON because secondary replicas do not support TOTP."
  type        = string
  default     = "OPTIONAL"
}

variable "primary_multi_region_kms_key_arn" {
  description = "Primary-Region ARN of the pool's symmetric multi-Region KMS key."
  type        = string
}

variable "secondary_multi_region_kms_key_arn" {
  description = "Secondary-Region replica ARN of the same symmetric multi-Region KMS key."
  type        = string
}

variable "key_configuration_verified" {
  description = "Explicit evidence that the primary pool was configured to use primary_multi_region_kms_key_arn before replica creation."
  type        = bool
  default     = false
}

variable "activate_replica" {
  description = "Activate only after a successful inactive replica review and failover rehearsal."
  type        = bool
  default     = false
}

variable "activation_gate" {
  description = "Required operational evidence when activate_replica is true."
  type = object({
    failover_runbook_url                 = string
    application_routing_ready            = bool
    replica_authentication_tested        = bool
    secondary_write_limitations_accepted = bool
    totp_limitation_accepted             = bool
    token_validation_ready               = bool
  })
  default  = null
  nullable = true
}

variable "tags" {
  description = "Replica ownership and allocation tags."
  type        = map(string)
  default     = { Environment = "production", Owner = "identity-platform" }
}
