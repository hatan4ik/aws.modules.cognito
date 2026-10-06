variable "primary_user_pool_id" {
  description = "ID of an existing MRR-eligible primary user pool. Its Region prefix must match primary_region."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}-(gov-|iso-|isob-)?[a-z]+-[0-9]_[A-Za-z0-9]+$", var.primary_user_pool_id))
    error_message = "primary_user_pool_id must be a Cognito user-pool ID such as us-east-2_AbCd1234."
  }
}

variable "primary_region" {
  description = "Region that owns the authoritative user pool. The default awscc provider passed to this module must target this Region."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}-(gov-|iso-|isob-)?[a-z]+-[0-9]$", var.primary_region))
    error_message = "primary_region must be an AWS Region code."
  }
}

variable "secondary_region" {
  description = "Single additional Region for the Cognito replica. The awscc.secondary provider passed to this module must target this Region."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}-(gov-|iso-|isob-)?[a-z]+-[0-9]$", var.secondary_region))
    error_message = "secondary_region must be an AWS Region code."
  }
}

variable "prerequisite_evidence" {
  description = "Fail-closed evidence for AWS's MRR prerequisites. Both ARNs must be regional replicas of the same symmetric multi-Region KMS key, and key_configuration_verified confirms the primary pool was configured to use that key before this module runs."
  type = object({
    feature_plan                       = string
    mfa_configuration                  = string
    primary_multi_region_kms_key_arn   = string
    secondary_multi_region_kms_key_arn = string
    key_configuration_verified         = bool
  })
  nullable = false

  validation {
    condition     = contains(["ESSENTIALS", "PLUS"], var.prerequisite_evidence.feature_plan)
    error_message = "MRR requires an ESSENTIALS or PLUS Cognito feature plan."
  }

  validation {
    condition     = contains(["ON", "OPTIONAL"], var.prerequisite_evidence.mfa_configuration)
    error_message = "prerequisite_evidence.mfa_configuration must report ON or OPTIONAL."
  }
}

variable "activate_replica" {
  description = "Whether to move the secondary from its safe initial INACTIVE state to ACTIVE. Activation requires every activation_gate acknowledgement."
  type        = bool
  default     = false
  nullable    = false
}

variable "activation_gate" {
  description = "Operational evidence required before ACTIVE. Null is valid only while activate_replica=false. These declarations belong in reviewed environment code and do not replace a failover exercise."
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

variable "secondary_email_configuration" {
  description = "Optional Region-local email delivery settings for the replica. SES identities and configuration sets must exist in secondary_region."
  type = object({
    configuration_set      = optional(string)
    email_sending_account  = optional(string)
    from                   = optional(string)
    reply_to_email_address = optional(string)
    source_arn             = optional(string)
  })
  default  = null
  nullable = true

  validation {
    condition = var.secondary_email_configuration == null ? true : (
      var.secondary_email_configuration.email_sending_account == null ? true :
      contains(["COGNITO_DEFAULT", "DEVELOPER"], var.secondary_email_configuration.email_sending_account)
    )
    error_message = "secondary_email_configuration.email_sending_account must be COGNITO_DEFAULT or DEVELOPER when set."
  }
}

variable "secondary_lambda_config" {
  description = "Optional Region-local Lambda triggers for the replica. Every populated ARN must name a function in secondary_region; the caller owns aws_lambda_permission for Cognito invocation."
  type = object({
    custom_message       = optional(string)
    post_authentication  = optional(string)
    post_confirmation    = optional(string)
    pre_authentication   = optional(string)
    pre_sign_up          = optional(string)
    pre_token_generation = optional(string)
    user_migration       = optional(string)
  })
  default  = null
  nullable = true
}

variable "tags" {
  description = "Tags applied when the replica is created and to its regional configuration."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for key in keys(var.tags) : !startswith(lower(key), "aws:")])
    error_message = "tags must not use the reserved aws: prefix."
  }
}
