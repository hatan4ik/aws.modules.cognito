variable "name" {
  description = "Lowercase Cognito user-pool name used in resource names and tags."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.name))
    error_message = "name must be 3-63 lowercase letters, digits, and hyphens and start with a letter."
  }
}

variable "feature_plan" {
  description = "Cognito feature plan. MRR requires ESSENTIALS or PLUS; LITE cannot meet this module's security contract."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["ESSENTIALS", "PLUS"], var.feature_plan)
    error_message = "feature_plan must be ESSENTIALS or PLUS."
  }
}

variable "deletion_protection" {
  description = "Whether AWS Cognito deletion protection remains active for this user pool."
  type        = bool
  nullable    = false
}

variable "mfa_configuration" {
  description = "Cognito MFA policy. Software-token MFA is enabled for either permitted secure value."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be ON or OPTIONAL; OFF is not permitted by this module."
  }
}

variable "password_policy" {
  description = "Explicit password-policy contract. Numeric values are product/security decisions, not module defaults."
  type = object({
    minimum_length                   = number
    temporary_password_validity_days = number
    password_history_size            = optional(number)
  })
  nullable = false

  validation {
    condition = (
      var.password_policy.minimum_length >= 8 &&
      var.password_policy.minimum_length <= 99 &&
      var.password_policy.temporary_password_validity_days >= 1 &&
      var.password_policy.temporary_password_validity_days <= 365 &&
      (var.password_policy.password_history_size == null ? true : (var.password_policy.password_history_size >= 0 && var.password_policy.password_history_size <= 24))
    )
    error_message = "password_policy needs a minimum length from 8 through 99, temporary validity from 1 through 365 days, and a history size from 0 through 24 when set."
  }
}

variable "clients" {
  description = "Stable client-keyed OAuth authorization-code clients. Callback and logout URLs must be reviewed application endpoints."
  type = map(object({
    callback_urls          = set(string)
    logout_urls            = set(string)
    allowed_oauth_scopes   = set(string)
    access_token_validity  = number
    id_token_validity      = number
    refresh_token_validity = number
    generate_secret        = bool
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for client in values(var.clients) : [
        length(client.callback_urls) > 0,
        alltrue([for url in client.callback_urls : can(regex("^https://", url))]),
        alltrue([for url in client.logout_urls : can(regex("^https://", url))]),
        client.access_token_validity > 0,
        client.id_token_validity > 0,
        client.refresh_token_validity > 0,
      ]
    ]))
    error_message = "Every client needs HTTPS callback/logout URLs and positive token validity values."
  }
}

variable "resource_servers" {
  description = "Stable resource-server keyed custom OAuth scope contracts."
  type = map(object({
    identifier = string
    name       = string
    scopes = map(object({
      description = string
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for server in values(var.resource_servers) : can(regex("^https://", server.identifier))])
    error_message = "Each resource server identifier must be an HTTPS URI."
  }
}

variable "schema_attributes" {
  description = "Additional standard or custom attributes beyond the module's built-in required, immutable, verified email attribute. Keys are attribute names (custom attributes are given the custom: prefix automatically by Cognito when name does not already have one)."
  type = map(object({
    attribute_data_type      = string
    mutable                  = optional(bool, true)
    required                 = optional(bool, false)
    developer_only_attribute = optional(bool, false)
    string_constraints = optional(object({
      min_length = optional(number)
      max_length = optional(number)
    }))
    number_constraints = optional(object({
      min_value = optional(number)
      max_value = optional(number)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for key in keys(var.schema_attributes) : key != "email"])
    error_message = "email is a built-in attribute of this module; declare additional attributes under a different name."
  }

  validation {
    condition     = alltrue([for attribute in values(var.schema_attributes) : contains(["String", "Number", "DateTime", "Boolean"], attribute.attribute_data_type)])
    error_message = "schema_attributes[*].attribute_data_type must be String, Number, DateTime, or Boolean."
  }

  validation {
    condition     = alltrue([for attribute in values(var.schema_attributes) : attribute.required ? attribute.mutable : true])
    error_message = "A required schema attribute must also be mutable; Cognito rejects an immutable required attribute at pool creation."
  }
}

variable "advanced_security_mode" {
  description = "Cognito advanced (adaptive, risk-based) security: OFF, AUDIT, or ENFORCED. Costs more and changes sign-in behaviour, so it defaults off."
  type        = string
  default     = "OFF"
  nullable    = false

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "lambda_config" {
  description = "Cognito Lambda triggers this module supports, by trigger name. Each value is a Lambda function ARN; the caller owns the function and its permission to be invoked by Cognito."
  type = object({
    pre_sign_up          = optional(string)
    post_confirmation    = optional(string)
    pre_authentication   = optional(string)
    post_authentication  = optional(string)
    custom_message       = optional(string)
    pre_token_generation = optional(string)
    user_migration       = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for arn in [
        var.lambda_config.pre_sign_up, var.lambda_config.post_confirmation,
        var.lambda_config.pre_authentication, var.lambda_config.post_authentication,
        var.lambda_config.custom_message, var.lambda_config.pre_token_generation,
        var.lambda_config.user_migration,
      ] : arn == null ? true : can(regex("^arn:[^:]+:lambda:[^:]+:[0-9]{12}:function:.+$", arn))
    ])
    error_message = "Every lambda_config value must be a Lambda function ARN."
  }
}

variable "email_configuration" {
  description = "Custom (SES-backed) email sender. Null keeps the Cognito default sender, which is fine for low-volume or non-production pools but is rate-limited and cannot be branded."
  type = object({
    source_arn             = string
    from_email_address     = optional(string)
    reply_to_email_address = optional(string)
    configuration_set      = optional(string)
  })
  default = null

  validation {
    condition     = var.email_configuration == null ? true : can(regex("^arn:[^:]+:ses:[^:]+:[0-9]{12}:identity/.+$", var.email_configuration.source_arn))
    error_message = "email_configuration.source_arn must be a verified SES identity ARN."
  }
}

variable "tags" {
  description = "Additional required allocation and ownership tags. Name and Component tags are computed by the module."
  type        = map(string)
  default     = {}
  nullable    = false
}
