# Integration suite: real apply in the caller's own account.
#
# Requires AWS credentials and a region from the environment (for example
# AWS_PROFILE and AWS_REGION, or the OIDC role assumed by the integration
# workflow). A Cognito user pool needs no VPC or other prerequisite, so the
# only fixture is a random suffix (tests/integration/setup) that keeps
# concurrent runs from colliding on the pool name. deletion_protection is
# false so terraform test's automatic destroy at the end of the run can
# delete the pool; ACTIVE deletion protection would block it.
#
# Run: terraform init -backend=false -test-directory=tests/integration
#      terraform test -test-directory=tests/integration -filter=tests/integration/smoke.tftest.hcl

provider "aws" {}

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "smoke" {
  variables {
    name                = "cognito-it-${run.setup.suffix}"
    feature_plan        = "ESSENTIALS"
    deletion_protection = false
    mfa_configuration   = "ON"

    password_policy = {
      minimum_length                   = 14
      temporary_password_validity_days = 7
    }

    clients = {
      web = {
        callback_urls          = ["https://app.example.com/callback"]
        logout_urls            = ["https://app.example.com/logout"]
        allowed_oauth_scopes   = ["openid", "email"]
        access_token_validity  = 60
        id_token_validity      = 60
        refresh_token_validity = 30
        generate_secret        = false
      }
    }

    tags = {
      IntegrationTest = "aws.modules.cognito"
      Disposable      = "true"
    }
  }

  assert {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+_[0-9A-Za-z]+$", output.user_pool.id)) && startswith(output.user_pool.arn, "arn:") && length(output.user_pool.endpoint) > 0
    error_message = "The real API must return a well-formed user-pool ID, ARN, and endpoint."
  }

  assert {
    condition     = contains(keys(output.client_ids), "web") && length(output.client_ids["web"]) > 0
    error_message = "The real API must return a client ID for the declared client."
  }

  assert {
    condition     = length(output.resource_server_scope_identifiers) == 0
    error_message = "No resource servers were declared, so none may exist."
  }

  assert {
    condition     = output.advanced_security_mode == "OFF"
    error_message = "advanced_security_mode must default to OFF when not declared."
  }
}
