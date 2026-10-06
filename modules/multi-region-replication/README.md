# Cognito multi-Region replication

Adopts an existing eligible Cognito user pool into AWS-native multi-Region replication (MRR). The module creates the single permitted secondary replica from the primary Region, manages its Region-local configuration through an explicit secondary provider, and keeps it `INACTIVE` until reviewed operational evidence authorizes activation.

This uses Terraform's AWS Cloud Control provider. It does **not** create or manage a CloudFormation stack.

## Before the first plan

AWS requires the primary pool to use the Essentials or Plus feature plan and to be encrypted with a symmetric customer-managed multi-Region KMS key whose replica is available in the secondary Region. The pool must also be on AWS's MRR-eligible Cognito infrastructure. The HashiCorp AWS provider currently has no user-pool key-configuration argument, so this submodule does not pretend it can retrofit that prerequisite.

Confirm the primary pool's eligibility and key configuration through the Cognito control plane before setting `key_configuration_verified = true`. The module additionally proves that the two supplied KMS ARNs:

- are in the declared primary and secondary Regions;
- are in the same AWS account; and
- carry the identical `mrk-...` multi-Region key ID.

AWS remains the authoritative eligibility check during `CreateUserPoolReplica`.

## Provider contract

```hcl
provider "awscc" {
  region = "us-east-2"
}

provider "awscc" {
  alias  = "secondary"
  region = "us-west-2"
}

module "replica" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git//modules/multi-region-replication?ref=<commit-sha>" # release tag

  providers = {
    awscc           = awscc
    awscc.secondary = awscc.secondary
  }

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
```

The first apply creates an `INACTIVE` secondary. Configure any Region-local SES identity and Lambda triggers, grant Cognito permission to invoke those functions, and test authentication against the replica before activation.

## Activation gate

Set `activate_replica = true` only in a reviewed follow-up change. The plan fails unless `activation_gate` records all of the following:

- an HTTPS failover runbook;
- application endpoint/managed-login routing readiness;
- a successful replica authentication test;
- acceptance that signup, password reset, and profile writes remain primary-only during failover;
- acceptance that TOTP MFA is unsupported in the secondary; and
- token validation that handles the multi-Region issuer contract.

MRR is eventually consistent and has additional cost. A replica provides an authentication continuity mechanism, not automatic application failover; the application or Cognito domain routing still needs a health signal and tested failover policy.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.92.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.92.0, < 2.0.0 |
| <a name="provider_awscc.secondary"></a> [awscc.secondary](#provider\_awscc.secondary) | >= 1.92.0, < 2.0.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [awscc_cognito_user_pool_regional_configuration_attachment.secondary](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/cognito_user_pool_regional_configuration_attachment) | resource |
| [awscc_cognito_user_pool_replica.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/cognito_user_pool_replica) | resource |
| [terraform_data.prerequisites](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activate_replica"></a> [activate\_replica](#input\_activate\_replica) | Whether to move the secondary from its safe initial INACTIVE state to ACTIVE. Activation requires every activation\_gate acknowledgement. | `bool` | `false` | no |
| <a name="input_activation_gate"></a> [activation\_gate](#input\_activation\_gate) | Operational evidence required before ACTIVE. Null is valid only while activate\_replica=false. These declarations belong in reviewed environment code and do not replace a failover exercise. | <pre>object({<br/>    failover_runbook_url                 = string<br/>    application_routing_ready            = bool<br/>    replica_authentication_tested        = bool<br/>    secondary_write_limitations_accepted = bool<br/>    totp_limitation_accepted             = bool<br/>    token_validation_ready               = bool<br/>  })</pre> | `null` | no |
| <a name="input_prerequisite_evidence"></a> [prerequisite\_evidence](#input\_prerequisite\_evidence) | Fail-closed evidence for AWS's MRR prerequisites. Both ARNs must be regional replicas of the same symmetric multi-Region KMS key, and key\_configuration\_verified confirms the primary pool was configured to use that key before this module runs. | <pre>object({<br/>    feature_plan                       = string<br/>    mfa_configuration                  = string<br/>    primary_multi_region_kms_key_arn   = string<br/>    secondary_multi_region_kms_key_arn = string<br/>    key_configuration_verified         = bool<br/>  })</pre> | n/a | yes |
| <a name="input_primary_region"></a> [primary\_region](#input\_primary\_region) | Region that owns the authoritative user pool. The default awscc provider passed to this module must target this Region. | `string` | n/a | yes |
| <a name="input_primary_user_pool_id"></a> [primary\_user\_pool\_id](#input\_primary\_user\_pool\_id) | ID of an existing MRR-eligible primary user pool. Its Region prefix must match primary\_region. | `string` | n/a | yes |
| <a name="input_secondary_email_configuration"></a> [secondary\_email\_configuration](#input\_secondary\_email\_configuration) | Optional Region-local email delivery settings for the replica. SES identities and configuration sets must exist in secondary\_region. | <pre>object({<br/>    configuration_set      = optional(string)<br/>    email_sending_account  = optional(string)<br/>    from                   = optional(string)<br/>    reply_to_email_address = optional(string)<br/>    source_arn             = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_secondary_lambda_config"></a> [secondary\_lambda\_config](#input\_secondary\_lambda\_config) | Optional Region-local Lambda triggers for the replica. Every populated ARN must name a function in secondary\_region; the caller owns aws\_lambda\_permission for Cognito invocation. | <pre>object({<br/>    custom_message       = optional(string)<br/>    post_authentication  = optional(string)<br/>    post_confirmation    = optional(string)<br/>    pre_authentication   = optional(string)<br/>    pre_sign_up          = optional(string)<br/>    pre_token_generation = optional(string)<br/>    user_migration       = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_secondary_region"></a> [secondary\_region](#input\_secondary\_region) | Single additional Region for the Cognito replica. The awscc.secondary provider passed to this module must target this Region. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied when the replica is created and to its regional configuration. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_replica"></a> [replica](#output\_replica) | Replica identity, Regions, activation status, and prerequisite key identity for application routing and DR evidence. |
<!-- END_TF_DOCS -->
