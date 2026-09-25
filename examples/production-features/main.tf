provider "aws" {
  region = var.region
}

# PLUS feature plan with adaptive, risk-based authentication enforced;
# additional schema attributes (one required mutable string, one immutable
# custom attribute); Lambda triggers for sign-up validation and post-
# confirmation provisioning; and a branded SES-backed email sender in place
# of the rate-limited Cognito default.
module "users" {
  source = "../../"

  name                   = var.name
  feature_plan           = "PLUS"
  deletion_protection    = true
  mfa_configuration      = "ON"
  advanced_security_mode = "ENFORCED"

  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
    password_history_size            = 12
  }

  schema_attributes = {
    full_name = {
      attribute_data_type = "String"
      required            = true
      mutable             = true
      string_constraints = {
        min_length = 1
        max_length = 128
      }
    }
    "custom:tenant_id" = {
      attribute_data_type = "String"
      mutable             = false
      string_constraints = {
        min_length = 1
        max_length = 36
      }
    }
  }

  lambda_config = {
    pre_sign_up       = var.pre_sign_up_lambda_arn
    post_confirmation = var.post_confirmation_lambda_arn
  }

  email_configuration = {
    source_arn         = var.ses_identity_arn
    from_email_address = "no-reply@example.com"
  }
}
