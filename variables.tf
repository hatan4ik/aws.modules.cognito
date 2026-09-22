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
  description = "Cognito feature plan. MRR requires ESSENTIALS or PLUS; the module rejects Terraform-managed MRR until provider support exists."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["ESSENTIALS", "PLUS"], var.feature_plan)
    error_message = "feature_plan must be ESSENTIALS or PLUS; LITE cannot meet the MRR architecture."
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
  })
  nullable = false

  validation {
    condition = (
      var.password_policy.minimum_length >= 8 &&
      var.password_policy.minimum_length <= 99 &&
      var.password_policy.temporary_password_validity_days >= 1 &&
      var.password_policy.temporary_password_validity_days <= 365
    )
    error_message = "password_policy needs a minimum length from 8 through 99 and temporary validity from 1 through 365 days."
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

variable "replication" {
  description = "MRR intent. Terraform-managed MRR is currently rejected because the AWS provider has no tracked resource for CreateUserPoolReplica/UpdateUserPoolReplica."
  type = object({
    enabled          = bool
    secondary_region = optional(string)
    kms_key_arn      = optional(string)
  })
  default = {
    enabled = false
  }
  nullable = false

  validation {
    condition = (
      !var.replication.enabled ||
      (try(length(var.replication.secondary_region) > 0, false) && try(can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.replication.kms_key_arn)), false))
    )
    error_message = "An MRR request must name a secondary Region and multi-Region KMS key ARN before provider support is evaluated."
  }
}

variable "tags" {
  description = "Additional required allocation and ownership tags. Name and Component tags are computed by the module."
  type        = map(string)
  default     = {}
  nullable    = false
}
