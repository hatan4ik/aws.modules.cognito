locals {
  primary_kms_arn_parts   = split(":", var.prerequisite_evidence.primary_multi_region_kms_key_arn)
  secondary_kms_arn_parts = split(":", var.prerequisite_evidence.secondary_multi_region_kms_key_arn)

  primary_kms_key_id   = try(element(reverse(split("/", var.prerequisite_evidence.primary_multi_region_kms_key_arn)), 0), "")
  secondary_kms_key_id = try(element(reverse(split("/", var.prerequisite_evidence.secondary_multi_region_kms_key_arn)), 0), "")

  secondary_lambda_arns = var.secondary_lambda_config == null ? [] : compact([
    var.secondary_lambda_config.custom_message,
    var.secondary_lambda_config.post_authentication,
    var.secondary_lambda_config.post_confirmation,
    var.secondary_lambda_config.pre_authentication,
    var.secondary_lambda_config.pre_sign_up,
    var.secondary_lambda_config.pre_token_generation,
    var.secondary_lambda_config.user_migration,
  ])
}
