mock_provider "awscc" {}

mock_provider "awscc" {
  alias = "secondary"
}

variables {
  primary_user_pool_id = "us-east-2_AbCd1234"
  primary_region       = "us-east-2"
  secondary_region     = "us-west-2"

  prerequisite_evidence = {
    feature_plan                       = "ESSENTIALS"
    mfa_configuration                  = "OPTIONAL"
    primary_multi_region_kms_key_arn   = "arn:aws:kms:us-east-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
    secondary_multi_region_kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
    key_configuration_verified         = true
  }
}

run "creates_an_inactive_replica_by_default" {
  command = plan

  assert {
    condition     = awscc_cognito_user_pool_replica.this.user_pool_id == "us-east-2_AbCd1234" && awscc_cognito_user_pool_replica.this.region_name == "us-west-2"
    error_message = "The primary control plane must create the replica in secondary_region."
  }

  assert {
    condition     = awscc_cognito_user_pool_regional_configuration_attachment.secondary.status == "INACTIVE"
    error_message = "A new replica must remain INACTIVE until the activation gate is complete."
  }
}

run "activates_only_with_complete_evidence" {
  command = plan

  variables {
    activate_replica = true
    activation_gate = {
      failover_runbook_url                 = "https://runbooks.example.com/cognito-failover"
      application_routing_ready            = true
      replica_authentication_tested        = true
      secondary_write_limitations_accepted = true
      totp_limitation_accepted             = true
      token_validation_ready               = true
    }
  }

  assert {
    condition     = awscc_cognito_user_pool_regional_configuration_attachment.secondary.status == "ACTIVE"
    error_message = "A replica with complete activation evidence must be ACTIVE."
  }
}

run "wires_secondary_regional_configuration" {
  command = plan

  variables {
    secondary_email_configuration = {
      email_sending_account = "DEVELOPER"
      source_arn            = "arn:aws:ses:us-west-2:111122223333:identity/auth.example.com"
    }
    secondary_lambda_config = {
      pre_sign_up = "arn:aws:lambda:us-west-2:111122223333:function:cognito-pre-sign-up"
    }
  }

  assert {
    condition = (
      awscc_cognito_user_pool_regional_configuration_attachment.secondary.email_configuration.source_arn == "arn:aws:ses:us-west-2:111122223333:identity/auth.example.com" &&
      awscc_cognito_user_pool_regional_configuration_attachment.secondary.lambda_config.pre_sign_up == "arn:aws:lambda:us-west-2:111122223333:function:cognito-pre-sign-up"
    )
    error_message = "Secondary SES and Lambda settings must be passed to the regional configuration attachment."
  }
}
