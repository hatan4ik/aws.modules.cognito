# Web app with custom scopes

One resource server with two custom OAuth scopes, and one authorization-code
client that requests both a standard OIDC scope and a custom scope.
`generate_secret = false` is the public-client pattern for a browser
single-page application, which cannot keep a client secret confidential.

## Run

```sh
terraform init
terraform plan \
  -var name=example-users \
  -var 'callback_urls=["https://app.example.com/callback"]' \
  -var 'logout_urls=["https://app.example.com/logout"]'
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
| <a name="input_callback_urls"></a> [callback\_urls](#input\_callback\_urls) | HTTPS callback URLs the browser SPA client redirects to after sign-in. | `set(string)` | n/a | yes |
| <a name="input_logout_urls"></a> [logout\_urls](#input\_logout\_urls) | HTTPS logout URLs the browser SPA client redirects to after sign-out. | `set(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Lowercase Cognito user-pool name. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region the user pool is created in. | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Application-client key to user-pool client ID mapping. |
| <a name="output_resource_server_scope_identifiers"></a> [resource\_server\_scope\_identifiers](#output\_resource\_server\_scope\_identifiers) | Custom resource-server scope identifiers. |
| <a name="output_user_pool"></a> [user\_pool](#output\_user\_pool) | Primary user-pool identifiers. |
<!-- END_TF_DOCS -->
