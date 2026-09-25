mock_provider "aws" {}

variables {
  name                = "sandbox-platform-dev-users"
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "ON"
  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }
}

run "plans_secure_primary_user_pool_with_platform_defaults" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.name == "sandbox-platform-dev-users" && aws_cognito_user_pool.this.user_pool_tier == "ESSENTIALS" && aws_cognito_user_pool.this.deletion_protection == "ACTIVE" && aws_cognito_user_pool.this.mfa_configuration == "ON"
    error_message = "The pool must carry the declared name, tier, deletion protection, and MFA policy."
  }

  assert {
    condition     = aws_cognito_user_pool.this.auto_verified_attributes == toset(["email"]) && aws_cognito_user_pool.this.username_attributes == toset(["email"]) && aws_cognito_user_pool.this.username_configuration[0].case_sensitive == false
    error_message = "Sign-in must be by case-insensitive verified email."
  }

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].minimum_length == 14 && aws_cognito_user_pool.this.password_policy[0].require_lowercase == true && aws_cognito_user_pool.this.password_policy[0].require_numbers == true && aws_cognito_user_pool.this.password_policy[0].require_symbols == true && aws_cognito_user_pool.this.password_policy[0].require_uppercase == true
    error_message = "The password policy must require every character class."
  }

  assert {
    condition     = aws_cognito_user_pool.this.software_token_mfa_configuration[0].enabled == true && contains([for m in aws_cognito_user_pool.this.account_recovery_setting[0].recovery_mechanism : m.name], "verified_email")
    error_message = "Software-token MFA and verified-email recovery must be enabled."
  }

  assert {
    condition     = length([for s in aws_cognito_user_pool.this.schema : s if s.name == "email"]) == 1 && [for s in aws_cognito_user_pool.this.schema : s if s.name == "email"][0].mutable == false && [for s in aws_cognito_user_pool.this.schema : s if s.name == "email"][0].required == true
    error_message = "The built-in email attribute must be required and immutable."
  }

  assert {
    condition     = aws_cognito_user_pool.this.user_pool_add_ons[0].advanced_security_mode == "OFF" && length(aws_cognito_user_pool.this.lambda_config) == 0 && length(aws_cognito_user_pool.this.email_configuration) == 0
    error_message = "Advanced security must default off and no Lambda triggers or custom email sender may render unless declared."
  }

  assert {
    condition     = length(aws_cognito_resource_server.this) == 0 && length(aws_cognito_user_pool_client.this) == 0
    error_message = "No clients or resource servers may exist unless declared."
  }

  assert {
    condition     = aws_cognito_user_pool.this.tags["Name"] == "sandbox-platform-dev-users" && aws_cognito_user_pool.this.tags["Component"] == "cognito-user-pool"
    error_message = "The pool must carry the platform Name and Component tags."
  }
}

run "renders_clients_and_resource_server_scopes" {
  command = plan

  variables {
    resource_servers = {
      api = {
        identifier = "https://api.example.test"
        name       = "test-api"
        scopes = {
          read  = { description = "Read test API data" }
          write = { description = "Write test API data" }
        }
      }
    }
    clients = {
      web = {
        callback_urls          = ["https://app.example.test/callback"]
        logout_urls            = ["https://app.example.test/logout"]
        allowed_oauth_scopes   = ["email", "openid", "profile", "https://api.example.test/read"]
        access_token_validity  = 60
        id_token_validity      = 60
        refresh_token_validity = 30
        generate_secret        = false
      }
    }
  }

  assert {
    condition     = aws_cognito_resource_server.this["api"].identifier == "https://api.example.test" && length(aws_cognito_resource_server.this["api"].scope) == 2
    error_message = "The resource server must render both declared scopes."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].name == "sandbox-platform-dev-users-web" && aws_cognito_user_pool_client.this["web"].allowed_oauth_flows == toset(["code"]) && aws_cognito_user_pool_client.this["web"].generate_secret == false
    error_message = "The client must be named after the pool and the client key, use authorization code, and honour generate_secret."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].access_token_validity == 60 && aws_cognito_user_pool_client.this["web"].token_validity_units[0].access_token == "minutes" && aws_cognito_user_pool_client.this["web"].token_validity_units[0].refresh_token == "days"
    error_message = "Token validity units must be minutes for access/id tokens and days for refresh tokens."
  }

  assert {
    condition     = contains(keys(output.client_ids), "web") && contains(keys(output.resource_server_scope_identifiers), "api")
    error_message = "Outputs must expose the client ID and resource-server scope identifiers."
  }
}

run "renders_new_v1_features_when_declared" {
  command = plan

  variables {
    advanced_security_mode = "ENFORCED"
    schema_attributes = {
      full_name          = { attribute_data_type = "String", required = true, string_constraints = { min_length = 1, max_length = 128 } }
      "custom:tenant_id" = { attribute_data_type = "String", mutable = false }
    }
    lambda_config = {
      pre_sign_up       = "arn:aws:lambda:us-east-2:123456789012:function:pre-signup"
      post_confirmation = "arn:aws:lambda:us-east-2:123456789012:function:post-confirmation"
    }
    email_configuration = {
      source_arn         = "arn:aws:ses:us-east-2:123456789012:identity/example.test"
      from_email_address = "no-reply@example.test"
    }
  }

  assert {
    condition     = aws_cognito_user_pool.this.user_pool_add_ons[0].advanced_security_mode == "ENFORCED"
    error_message = "advanced_security_mode must pass through."
  }

  assert {
    condition     = length([for s in aws_cognito_user_pool.this.schema : s if s.name == "full_name"]) == 1 && tonumber([for s in aws_cognito_user_pool.this.schema : s if s.name == "full_name"][0].string_attribute_constraints[0].max_length) == 128 && length([for s in aws_cognito_user_pool.this.schema : s if s.name == "custom:tenant_id"]) == 1
    error_message = "Additional schema attributes, including a caller-prefixed custom attribute, must render with their constraints."
  }

  assert {
    condition     = aws_cognito_user_pool.this.lambda_config[0].pre_sign_up == "arn:aws:lambda:us-east-2:123456789012:function:pre-signup" && aws_cognito_user_pool.this.lambda_config[0].post_confirmation == "arn:aws:lambda:us-east-2:123456789012:function:post-confirmation"
    error_message = "Declared Lambda triggers must render."
  }

  assert {
    condition     = aws_cognito_user_pool.this.email_configuration[0].email_sending_account == "DEVELOPER" && aws_cognito_user_pool.this.email_configuration[0].source_arn == "arn:aws:ses:us-east-2:123456789012:identity/example.test" && aws_cognito_user_pool.this.email_configuration[0].from_email_address == "no-reply@example.test"
    error_message = "A declared custom email sender must switch to DEVELOPER sending and carry the SES identity."
  }
}

run "rejects_a_scope_from_an_undeclared_resource_server" {
  command = plan

  variables {
    clients = {
      web = {
        callback_urls          = ["https://app.example.test/callback"]
        logout_urls            = ["https://app.example.test/logout"]
        allowed_oauth_scopes   = ["https://unknown.example.test/read"]
        access_token_validity  = 60
        id_token_validity      = 60
        refresh_token_validity = 30
        generate_secret        = false
      }
    }
  }

  expect_failures = [aws_cognito_user_pool_client.this]
}

run "rejects_reusing_the_built_in_email_attribute_name" {
  command = plan
  variables {
    schema_attributes = { email = { attribute_data_type = "String" } }
  }
  expect_failures = [var.schema_attributes]
}

run "rejects_required_immutable_schema_attribute" {
  command = plan
  variables {
    schema_attributes = { full_name = { attribute_data_type = "String", required = true, mutable = false } }
  }
  expect_failures = [var.schema_attributes]
}

run "rejects_invalid_advanced_security_mode" {
  command = plan
  variables {
    advanced_security_mode = "AUDIT_MODE"
  }
  expect_failures = [var.advanced_security_mode]
}

run "rejects_malformed_lambda_arn" {
  command = plan
  variables {
    lambda_config = { pre_sign_up = "not-an-arn" }
  }
  expect_failures = [var.lambda_config]
}

run "rejects_non_ses_email_source" {
  command = plan
  variables {
    email_configuration = { source_arn = "arn:aws:sns:us-east-2:123456789012:topic/foo" }
  }
  expect_failures = [var.email_configuration]
}

run "rejects_client_without_callback_url" {
  command = plan
  variables {
    clients = {
      web = {
        callback_urls          = []
        logout_urls            = ["https://app.example.test/logout"]
        allowed_oauth_scopes   = ["openid"]
        access_token_validity  = 60
        id_token_validity      = 60
        refresh_token_validity = 30
        generate_secret        = false
      }
    }
  }
  expect_failures = [var.clients]
}

run "rejects_password_history_out_of_range" {
  command = plan
  variables {
    password_policy = {
      minimum_length                   = 14
      temporary_password_validity_days = 7
      password_history_size            = 30
    }
  }
  expect_failures = [var.password_policy]
}
