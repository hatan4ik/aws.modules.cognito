module "replica" {
  source = "../../modules/multi-region-replication"

  providers = {
    awscc           = awscc
    awscc.secondary = awscc.secondary
  }

  primary_user_pool_id = var.primary_user_pool_id
  primary_region       = var.primary_region
  secondary_region     = var.secondary_region
  prerequisite_evidence = {
    feature_plan                       = var.feature_plan
    mfa_configuration                  = var.mfa_configuration
    primary_multi_region_kms_key_arn   = var.primary_multi_region_kms_key_arn
    secondary_multi_region_kms_key_arn = var.secondary_multi_region_kms_key_arn
    key_configuration_verified         = var.key_configuration_verified
  }

  # Keep the first apply INACTIVE. Set true only in a reviewed follow-up after
  # the runbook gates below have been exercised and changed to true.
  activate_replica = var.activate_replica
  activation_gate  = var.activation_gate

  tags = var.tags
}
