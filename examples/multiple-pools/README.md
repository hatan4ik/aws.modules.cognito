# Multiple pools

A `for_each` over a map of pools, one per environment, each with its own
`deletion_protection` and `mfa_configuration`. One module call is one user
pool; a fleet is a `for_each` over the module block so each environment keeps
its own plan and lifecycle.

## Run

```sh
terraform init
terraform plan -var 'pools={
  dev     = { name = "example-dev-users", deletion_protection = false, mfa_configuration = "OPTIONAL" }
  staging = { name = "example-staging-users", deletion_protection = true, mfa_configuration = "ON" }
}'
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
| <a name="module_pool"></a> [pool](#module\_pool) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_pools"></a> [pools](#input\_pools) | User pools to create, keyed by environment. Each entry names the pool and sets its own deletion protection and MFA policy, since a non-production pool is often torn down and does not need the same guardrails as production. | <pre>map(object({<br/>    name                = string<br/>    deletion_protection = bool<br/>    mfa_configuration   = string<br/>  }))</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region the user pools are created in. | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user_pools"></a> [user\_pools](#output\_user\_pools) | Primary user-pool identifiers keyed by environment. |
<!-- END_TF_DOCS -->
