# Production features

The `PLUS` feature plan with advanced (adaptive, risk-based) security
enforced, additional schema attributes (one required mutable string and one
immutable `custom:` attribute), Lambda triggers for `pre_sign_up` and
`post_confirmation`, and a branded SES-backed email sender in place of the
rate-limited Cognito default sender.

## Run

```sh
terraform init
terraform plan \
  -var name=example-users \
  -var pre_sign_up_lambda_arn=arn:aws:lambda:us-east-1:123456789012:function:pre-sign-up \
  -var post_confirmation_lambda_arn=arn:aws:lambda:us-east-1:123456789012:function:post-confirmation \
  -var ses_identity_arn=arn:aws:ses:us-east-1:123456789012:identity/example.com
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_users"></a> [users](#module\_users) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Lowercase Cognito user-pool name. | `string` | n/a | yes |
| <a name="input_post_confirmation_lambda_arn"></a> [post\_confirmation\_lambda\_arn](#input\_post\_confirmation\_lambda\_arn) | ARN of the Lambda function invoked on the PostConfirmation trigger. | `string` | n/a | yes |
| <a name="input_pre_sign_up_lambda_arn"></a> [pre\_sign\_up\_lambda\_arn](#input\_pre\_sign\_up\_lambda\_arn) | ARN of the Lambda function invoked on the PreSignUp trigger. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region the user pool is created in. | `string` | `"us-east-1"` | no |
| <a name="input_ses_identity_arn"></a> [ses\_identity\_arn](#input\_ses\_identity\_arn) | ARN of the verified SES identity used to send account emails. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_advanced_security_mode"></a> [advanced\_security\_mode](#output\_advanced\_security\_mode) | The advanced security mode this pool was created with. |
| <a name="output_user_pool"></a> [user\_pool](#output\_user\_pool) | Primary user-pool identifiers. |
<!-- END_TF_DOCS -->
