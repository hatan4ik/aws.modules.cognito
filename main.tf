resource "terraform_data" "mrr_provider_capability" {
  input = var.replication

  lifecycle {
    precondition {
      condition     = !var.replication.enabled
      error_message = "Terraform-managed Cognito MRR is blocked: the AWS provider lacks a resource for CreateUserPoolReplica and UpdateUserPoolReplica. Do not replace this guard with a local-exec or untracked CLI call; adopt a provider-backed resource in a reviewed ADR amendment first."
    }
  }
}

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
}
