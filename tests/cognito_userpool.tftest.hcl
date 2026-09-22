mock_provider "aws" {}

variables {
  name                = "test-auth-primary"
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "ON"
  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }
  clients = {
    web = {
      callback_urls          = ["https://app.example.test/callback"]
      logout_urls            = ["https://app.example.test/logout"]
      allowed_oauth_scopes   = ["email", "openid", "profile"]
      access_token_validity  = 60
      id_token_validity      = 60
      refresh_token_validity = 30
      generate_secret        = false
    }
  }
  resource_servers = {
    api = {
      identifier = "https://api.example.test"
      name       = "test-api"
      scopes = {
        read = {
          description = "Read test API data"
        }
      }
    }
  }
}

run "plans_secure_primary_user_pool" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.user_pool_tier == "ESSENTIALS" && aws_cognito_user_pool.this.deletion_protection == "ACTIVE"
    error_message = "The primary pool must use an MRR-capable tier and retain deletion protection."
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "ON" && contains(aws_cognito_user_pool.this.username_attributes, "email")
    error_message = "The primary pool must require MFA and use verified email sign-in."
  }

  assert {
    condition     = length(aws_cognito_user_pool_client.this) == 1 && length(aws_cognito_resource_server.this) == 1
    error_message = "The module must plan the supplied client and custom-scope contract."
  }
}

run "rejects_terraform_managed_replication" {
  command = plan

  variables {
    replication = {
      enabled          = true
      secondary_region = "us-west-2"
      kms_key_arn      = "arn:aws:kms:us-east-2:111122223333:key/11111111-1111-1111-1111-111111111111"
    }
  }

  expect_failures = [terraform_data.mrr_provider_capability]
}
