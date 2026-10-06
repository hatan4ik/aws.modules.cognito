output "replica" {
  description = "Replica identity, Regions, activation status, and prerequisite key identity for application routing and DR evidence."
  value = {
    id                  = awscc_cognito_user_pool_replica.this.id
    user_pool_id        = var.primary_user_pool_id
    primary_region      = var.primary_region
    secondary_region    = var.secondary_region
    status              = var.activate_replica ? "ACTIVE" : "INACTIVE"
    regional_config_id  = awscc_cognito_user_pool_regional_configuration_attachment.secondary.id
    multi_region_key_id = local.primary_kms_key_id
  }
}
