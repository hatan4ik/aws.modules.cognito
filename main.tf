resource "aws_cognito_user_pool" "this" {
  name                = var.name
  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"
  mfa_configuration   = var.mfa_configuration
  user_pool_tier      = var.feature_plan

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
    password_history_size            = var.password_policy.password_history_size
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "Verify your sign-in"
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  schema {
    attribute_data_type = "String"
    mutable             = false
    name                = "email"
    required            = true

    string_attribute_constraints {
      min_length = 5
      max_length = 320
    }
  }

  dynamic "schema" {
    for_each = var.schema_attributes

    content {
      attribute_data_type      = schema.value.attribute_data_type
      mutable                  = schema.value.mutable
      required                 = schema.value.required
      developer_only_attribute = schema.value.developer_only_attribute
      name                     = schema.key

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" && schema.value.string_constraints != null ? [schema.value.string_constraints] : []

        content {
          min_length = string_attribute_constraints.value.min_length
          max_length = string_attribute_constraints.value.max_length
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "Number" && schema.value.number_constraints != null ? [schema.value.number_constraints] : []

        content {
          min_value = number_attribute_constraints.value.min_value
          max_value = number_attribute_constraints.value.max_value
        }
      }
    }
  }

  dynamic "lambda_config" {
    for_each = length(local.lambda_config) == 0 ? [] : [var.lambda_config]

    content {
      pre_sign_up          = lambda_config.value.pre_sign_up
      post_confirmation    = lambda_config.value.post_confirmation
      pre_authentication   = lambda_config.value.pre_authentication
      post_authentication  = lambda_config.value.post_authentication
      custom_message       = lambda_config.value.custom_message
      pre_token_generation = lambda_config.value.pre_token_generation
      user_migration       = lambda_config.value.user_migration
    }
  }

  dynamic "email_configuration" {
    for_each = var.email_configuration == null ? [] : [var.email_configuration]

    content {
      email_sending_account  = "DEVELOPER"
      source_arn             = email_configuration.value.source_arn
      from_email_address     = email_configuration.value.from_email_address
      reply_to_email_address = email_configuration.value.reply_to_email_address
      configuration_set      = email_configuration.value.configuration_set
    }
  }

  tags = local.common_tags
}

resource "aws_cognito_resource_server" "this" {
  for_each = var.resource_servers

  identifier   = each.value.identifier
  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "scope" {
    for_each = each.value.scopes

    content {
      scope_name        = scope.key
      scope_description = scope.value.description
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = var.clients

  name                                 = "${var.name}-${each.key}"
  user_pool_id                         = aws_cognito_user_pool.this.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = tolist(each.value.allowed_oauth_scopes)
  callback_urls                        = tolist(each.value.callback_urls)
  logout_urls                          = tolist(each.value.logout_urls)
  enable_token_revocation              = true
  generate_secret                      = each.value.generate_secret
  prevent_user_existence_errors        = "ENABLED"
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_AUTH"]

  access_token_validity  = each.value.access_token_validity
  id_token_validity      = each.value.id_token_validity
  refresh_token_validity = each.value.refresh_token_validity

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for scope in each.value.allowed_oauth_scopes :
        contains(["openid", "email", "profile", "phone", "aws.cognito.signin.user.admin"], scope) ||
        anytrue([for server in values(var.resource_servers) : startswith(scope, "${server.identifier}/") && contains(keys(server.scopes), trimprefix(scope, "${server.identifier}/"))])
      ])
      error_message = "Every non-standard OAuth scope on client \"${each.key}\" must be <resource_server_identifier>/<scope_name> for a scope declared in resource_servers, or one of the standard OIDC scopes."
    }
  }
}
