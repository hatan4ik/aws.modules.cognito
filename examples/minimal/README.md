# Minimal user pool

The smallest working call of `aws.modules.cognito`: verified-email sign-in, a
strong password policy, and MFA required. No clients and no resource servers;
add them once an application is ready to authenticate against this pool. This
is the starting point in the root [Quick start](../../README.md#quick-start).

## Run

```sh
terraform init
terraform plan -var name=example-users
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
| <a name="input_region"></a> [region](#input\_region) | AWS region the user pool is created in. | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user_pool"></a> [user\_pool](#output\_user\_pool) | Primary user-pool identifiers. |
<!-- END_TF_DOCS -->
