mock_provider "awscc" {}

mock_provider "awscc" {
  alias = "secondary"
}

variables {
  primary_user_pool_id = "us-east-2_AbCd1234"
  primary_region       = "us-east-2"
  secondary_region     = "us-west-2"

  prerequisite_evidence = {
    feature_plan                       = "PLUS"
    mfa_configuration                  = "OPTIONAL"
    primary_multi_region_kms_key_arn   = "arn:aws:kms:us-east-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
    secondary_multi_region_kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
    key_configuration_verified         = true
  }
}

run "rejects_the_same_primary_and_secondary_region" {
  command = plan
  variables { secondary_region = "us-east-2" }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_a_pool_from_another_primary_region" {
  command = plan
  variables { primary_user_pool_id = "us-east-1_AbCd1234" }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_unverified_primary_key_configuration" {
  command = plan
  variables {
    prerequisite_evidence = {
      feature_plan                       = "PLUS"
      mfa_configuration                  = "OPTIONAL"
      primary_multi_region_kms_key_arn   = "arn:aws:kms:us-east-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
      secondary_multi_region_kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
      key_configuration_verified         = false
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_unrelated_kms_keys" {
  command = plan
  variables {
    prerequisite_evidence = {
      feature_plan                       = "PLUS"
      mfa_configuration                  = "OPTIONAL"
      primary_multi_region_kms_key_arn   = "arn:aws:kms:us-east-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
      secondary_multi_region_kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/mrk-fedcba9876543210fedcba9876543210"
      key_configuration_verified         = true
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_malformed_kms_arns_without_an_index_error" {
  command = plan
  variables {
    prerequisite_evidence = {
      feature_plan                       = "PLUS"
      mfa_configuration                  = "OPTIONAL"
      primary_multi_region_kms_key_arn   = "not-an-arn"
      secondary_multi_region_kms_key_arn = "also-not-an-arn"
      key_configuration_verified         = true
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_a_secondary_trigger_in_the_primary_region" {
  command = plan
  variables {
    secondary_lambda_config = {
      pre_sign_up = "arn:aws:lambda:us-east-2:111122223333:function:wrong-region"
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_developer_email_without_an_ses_identity" {
  command = plan
  variables {
    secondary_email_configuration = {
      email_sending_account = "DEVELOPER"
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_activation_without_readiness_evidence" {
  command = plan
  variables { activate_replica = true }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_activation_when_totp_mfa_is_mandatory" {
  command = plan
  variables {
    activate_replica = true
    prerequisite_evidence = {
      feature_plan                       = "PLUS"
      mfa_configuration                  = "ON"
      primary_multi_region_kms_key_arn   = "arn:aws:kms:us-east-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
      secondary_multi_region_kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/mrk-0123456789abcdef0123456789abcdef"
      key_configuration_verified         = true
    }
    activation_gate = {
      failover_runbook_url                 = "https://runbooks.example.com/cognito-failover"
      application_routing_ready            = true
      replica_authentication_tested        = true
      secondary_write_limitations_accepted = true
      totp_limitation_accepted             = true
      token_validation_ready               = true
    }
  }
  expect_failures = [terraform_data.prerequisites]
}

run "rejects_an_incomplete_activation_gate" {
  command = plan
  variables {
    activate_replica = true
    activation_gate = {
      failover_runbook_url                 = "https://runbooks.example.com/cognito-failover"
      application_routing_ready            = true
      replica_authentication_tested        = false
      secondary_write_limitations_accepted = true
      totp_limitation_accepted             = true
      token_validation_ready               = true
    }
  }
  expect_failures = [terraform_data.prerequisites]
}
