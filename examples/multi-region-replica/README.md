# Multi-Region replica

Creates one native Cognito MRR replica with explicit primary and secondary AWS Cloud Control providers. The initial plan is deliberately `INACTIVE`; activation is a separate reviewed change after regional settings, application routing, token validation, and the failover runbook have been tested.

This example assumes the existing primary pool is already eligible, uses Essentials or Plus, and was configured with the primary replica of the declared multi-Region KMS key. The current HashiCorp AWS provider does not expose that primary-pool key configuration, so the root Cognito module cannot safely retrofit it.

```hcl
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.92.0, < 2.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_replica"></a> [replica](#module\_replica) | ../../modules/multi-region-replication | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activate_replica"></a> [activate\_replica](#input\_activate\_replica) | Activate only after a successful inactive replica review and failover rehearsal. | `bool` | `false` | no |
| <a name="input_activation_gate"></a> [activation\_gate](#input\_activation\_gate) | Required operational evidence when activate\_replica is true. | <pre>object({<br/>    failover_runbook_url                 = string<br/>    application_routing_ready            = bool<br/>    replica_authentication_tested        = bool<br/>    secondary_write_limitations_accepted = bool<br/>    totp_limitation_accepted             = bool<br/>    token_validation_ready               = bool<br/>  })</pre> | `null` | no |
| <a name="input_feature_plan"></a> [feature\_plan](#input\_feature\_plan) | Primary pool feature plan. | `string` | `"ESSENTIALS"` | no |
| <a name="input_key_configuration_verified"></a> [key\_configuration\_verified](#input\_key\_configuration\_verified) | Explicit evidence that the primary pool was configured to use primary\_multi\_region\_kms\_key\_arn before replica creation. | `bool` | `false` | no |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | Primary pool MFA policy. ACTIVE is blocked for ON because secondary replicas do not support TOTP. | `string` | `"OPTIONAL"` | no |
| <a name="input_primary_multi_region_kms_key_arn"></a> [primary\_multi\_region\_kms\_key\_arn](#input\_primary\_multi\_region\_kms\_key\_arn) | Primary-Region ARN of the pool's symmetric multi-Region KMS key. | `string` | n/a | yes |
| <a name="input_primary_region"></a> [primary\_region](#input\_primary\_region) | Authoritative user-pool Region. | `string` | `"us-east-2"` | no |
| <a name="input_primary_user_pool_id"></a> [primary\_user\_pool\_id](#input\_primary\_user\_pool\_id) | Existing eligible primary Cognito user-pool ID. | `string` | n/a | yes |
| <a name="input_secondary_multi_region_kms_key_arn"></a> [secondary\_multi\_region\_kms\_key\_arn](#input\_secondary\_multi\_region\_kms\_key\_arn) | Secondary-Region replica ARN of the same symmetric multi-Region KMS key. | `string` | n/a | yes |
| <a name="input_secondary_region"></a> [secondary\_region](#input\_secondary\_region) | Replica Region. | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Replica ownership and allocation tags. | `map(string)` | <pre>{<br/>  "Environment": "production",<br/>  "Owner": "identity-platform"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_replica"></a> [replica](#output\_replica) | Inactive-by-default replica contract. |
<!-- END_TF_DOCS -->
