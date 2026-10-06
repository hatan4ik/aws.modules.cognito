# AWS's primary-pool eligibility and KMS configuration are not exposed by the
# HashiCorp AWS provider today. Keep the evidence explicit in state and fail at
# plan before asking Cognito to create a replica with incomplete prerequisites.
resource "terraform_data" "prerequisites" {
  input = {
    primary_user_pool_id  = var.primary_user_pool_id
    primary_region        = var.primary_region
    secondary_region      = var.secondary_region
    prerequisite_evidence = var.prerequisite_evidence
  }

  lifecycle {
    precondition {
      condition     = var.primary_region != var.secondary_region
      error_message = "primary_region and secondary_region must be different."
    }

    precondition {
      condition     = startswith(var.primary_user_pool_id, "${var.primary_region}_")
      error_message = "primary_user_pool_id must have the primary_region prefix."
    }

    precondition {
      condition = try(
        length(local.primary_kms_arn_parts) == 6 &&
        length(local.secondary_kms_arn_parts) == 6 &&
        local.primary_kms_arn_parts[0] == "arn" &&
        local.secondary_kms_arn_parts[0] == "arn" &&
        local.primary_kms_arn_parts[1] == local.secondary_kms_arn_parts[1] &&
        local.primary_kms_arn_parts[2] == "kms" &&
        local.secondary_kms_arn_parts[2] == "kms" &&
        local.primary_kms_arn_parts[3] == var.primary_region &&
        local.secondary_kms_arn_parts[3] == var.secondary_region &&
        can(regex("^[0-9]{12}$", local.primary_kms_arn_parts[4])) &&
        local.primary_kms_arn_parts[4] == local.secondary_kms_arn_parts[4] &&
        can(regex("^mrk-[0-9a-f]{32}$", local.primary_kms_key_id)) &&
        local.primary_kms_key_id == local.secondary_kms_key_id,
        false
      )
      error_message = "prerequisite_evidence must name regional replicas of the same multi-Region KMS key in the primary and secondary Regions and account."
    }

    precondition {
      condition     = var.prerequisite_evidence.key_configuration_verified
      error_message = "Verify that the primary user pool is configured with the declared multi-Region KMS key before creating its replica."
    }

    precondition {
      condition     = !var.activate_replica || var.prerequisite_evidence.mfa_configuration != "ON"
      error_message = "The replica cannot be activated for a pool with mfa_configuration=ON: Cognito MRR secondary Regions do not support TOTP MFA, and this module's primary pool supports software-token MFA only."
    }

    precondition {
      condition = var.secondary_email_configuration == null ? true : (
        var.secondary_email_configuration.source_arn == null ? true :
        can(regex("^arn:[^:]+:ses:${var.secondary_region}:[0-9]{12}:identity/.+$", var.secondary_email_configuration.source_arn))
      )
      error_message = "secondary_email_configuration.source_arn must be an SES identity in secondary_region."
    }

    precondition {
      condition = var.secondary_email_configuration == null ? true : (
        var.secondary_email_configuration.email_sending_account != "DEVELOPER" ||
        var.secondary_email_configuration.source_arn != null
      )
      error_message = "secondary_email_configuration requires source_arn when email_sending_account is DEVELOPER."
    }

    precondition {
      condition = alltrue([
        for arn in local.secondary_lambda_arns :
        can(regex("^arn:[^:]+:lambda:${var.secondary_region}:[0-9]{12}:function:[A-Za-z0-9-_]+(?::[A-Za-z0-9-_]+)?$", arn))
      ])
      error_message = "Every secondary Lambda trigger ARN must name a function or alias in secondary_region."
    }

    precondition {
      condition = !var.activate_replica || try(
        can(regex("^https://", var.activation_gate.failover_runbook_url)) &&
        var.activation_gate.application_routing_ready &&
        var.activation_gate.replica_authentication_tested &&
        var.activation_gate.secondary_write_limitations_accepted &&
        var.activation_gate.totp_limitation_accepted &&
        var.activation_gate.token_validation_ready,
        false
      )
      error_message = "activate_replica=true requires an HTTPS failover runbook and every activation_gate readiness acknowledgement."
    }
  }
}

# CreateUserPoolReplica is a primary-Region control-plane operation. The target
# Region is an argument, so the default awscc provider must be primary.
resource "awscc_cognito_user_pool_replica" "this" {
  user_pool_id             = var.primary_user_pool_id
  region_name              = var.secondary_region
  user_pool_tags_at_create = var.tags

  depends_on = [terraform_data.prerequisites]
}

# Regional settings and activation are managed through the replica endpoint.
# The aliased provider makes that ownership visible at every call site.
resource "awscc_cognito_user_pool_regional_configuration_attachment" "secondary" {
  provider = awscc.secondary

  user_pool_id        = var.primary_user_pool_id
  status              = var.activate_replica ? "ACTIVE" : "INACTIVE"
  email_configuration = var.secondary_email_configuration
  lambda_config       = var.secondary_lambda_config
  user_pool_tags      = var.tags

  depends_on = [awscc_cognito_user_pool_replica.this]
}
