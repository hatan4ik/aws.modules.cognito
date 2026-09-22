# terraform-aws-cognito-userpool

Creates the secure primary-user-pool contract: Essentials/Plus only, verified email sign-in, password-strength requirements, software-token MFA, protected account recovery, OAuth authorization-code clients, and typed resource-server scopes. Client secrets are never output.

## Critical MRR boundary

AWS Cognito MRR needs a multi-Region KMS key, `KeyConfiguration`, and the `CreateUserPoolReplica` / `UpdateUserPoolReplica` APIs. As of this implementation, the HashiCorp AWS provider exposes neither a Terraform resource for those operations nor the user-pool KMS/issuer fields required for this MRR contract. The module deliberately fails any request to manage MRR rather than using `local-exec`, an untracked AWS CLI call, or an independently created second user pool. The provider-backed remedy needs an ADR amendment, import/migration plan, and tests before production use.

See ADR 0002 and ADR 0006. The Phase 6 module-release workflow checks that the generated `terraform-docs` section below is current.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.65.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cognito_resource_server.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [terraform_data.mrr_provider_capability](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_clients"></a> [clients](#input\_clients) | Stable client-keyed OAuth authorization-code clients. Callback and logout URLs must be reviewed application endpoints. | <pre>map(object({<br/>    callback_urls          = set(string)<br/>    logout_urls            = set(string)<br/>    allowed_oauth_scopes   = set(string)<br/>    access_token_validity  = number<br/>    id_token_validity      = number<br/>    refresh_token_validity = number<br/>    generate_secret        = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether AWS Cognito deletion protection remains active for this user pool. | `bool` | n/a | yes |
| <a name="input_feature_plan"></a> [feature\_plan](#input\_feature\_plan) | Cognito feature plan. MRR requires ESSENTIALS or PLUS; the module rejects Terraform-managed MRR until provider support exists. | `string` | n/a | yes |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | Cognito MFA policy. Software-token MFA is enabled for either permitted secure value. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Lowercase Cognito user-pool name used in resource names and tags. | `string` | n/a | yes |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Explicit password-policy contract. Numeric values are product/security decisions, not module defaults. | <pre>object({<br/>    minimum_length                   = number<br/>    temporary_password_validity_days = number<br/>  })</pre> | n/a | yes |
| <a name="input_replication"></a> [replication](#input\_replication) | MRR intent. Terraform-managed MRR is currently rejected because the AWS provider has no tracked resource for CreateUserPoolReplica/UpdateUserPoolReplica. | <pre>object({<br/>    enabled          = bool<br/>    secondary_region = optional(string)<br/>    kms_key_arn      = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_resource_servers"></a> [resource\_servers](#input\_resource\_servers) | Stable resource-server keyed custom OAuth scope contracts. | <pre>map(object({<br/>    identifier = string<br/>    name       = string<br/>    scopes = map(object({<br/>      description = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional required allocation and ownership tags. Name and Component tags are computed by the module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Stable application-client key to user-pool client ID mapping. Client secrets are deliberately not output. |
| <a name="output_replication_status"></a> [replication\_status](#output\_replication\_status) | Explicit indication that MRR must remain blocked until a provider-backed resource supports the AWS APIs. |
| <a name="output_resource_server_scope_identifiers"></a> [resource\_server\_scope\_identifiers](#output\_resource\_server\_scope\_identifiers) | Stable custom resource-server scope identifiers for API authorization configuration. |
| <a name="output_user_pool"></a> [user\_pool](#output\_user\_pool) | Primary user-pool identifiers required by application token validation and supported Cognito configuration. |
<!-- END_TF_DOCS -->
