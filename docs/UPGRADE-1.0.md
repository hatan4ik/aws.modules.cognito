# Upgrading from 0.1.x to 1.0.0

## What changed and why

Version 0.1.x provisioned one Cognito user pool with verified-email sign-in, a caller-declared password policy, software-token MFA, OAuth authorization-code clients, and typed custom resource-server scopes. It also carried a `replication` input that a precondition rejected whenever `enabled = true`, so the input could never be validly set to anything but its own default — dead weight that documented an unbuilt feature as if it were a real, merely-restricted one. Version 1.0.0 removes that input, keeps every other input and output exactly as it was, and adds what production callers actually needed: additional schema attributes, advanced (adaptive, risk-based) security, Lambda triggers, and a custom SES-backed email sender. The reasons, and the full table of v0.1.x behaviours that were replaced, are in [DESIGN.md](DESIGN.md).

**The headline: this upgrade needs no `moved` blocks and no state migration.** `aws_cognito_user_pool.this`, `aws_cognito_resource_server.this`, and `aws_cognito_user_pool_client.this` are identical resource addresses in v1. Any consumer that already left `replication` unset, or left it at its only valid value (`{ enabled = false }`), needs no configuration change at all — the field defaulted to disabled, so removing it changes nothing about what was actually being requested.

## Input mapping

Root inputs of 0.1.1:

| 0.1.x input | 1.0.0 equivalent |
| --- | --- |
| `name` | `name`, unchanged. |
| `feature_plan` | `feature_plan`, unchanged. |
| `deletion_protection` | `deletion_protection`, unchanged. |
| `mfa_configuration` | `mfa_configuration`, unchanged. |
| `password_policy` | `password_policy`, unchanged shape, with a new optional `password_history_size` (0–24). Omitting it keeps the 0.1.x behaviour (no history requirement). |
| `clients` | `clients`, unchanged. |
| `resource_servers` | `resource_servers`, unchanged. |
| `replication` | **Removed, with no replacement.** Any consumer that never set `replication.enabled = true` needs no change: the input always defaulted to `{ enabled = false }`, and a precondition rejected every other value, so no working configuration ever depended on this input doing anything. |
| `tags` | `tags`, unchanged. |

Every input not listed above did not exist in 0.1.x and needs no mapping.

New in 1.0.0, all optional and all defaulting to no-op behaviour:

| New input | Default | What it adds |
| --- | --- | --- |
| `schema_attributes` | `{}` | Additional standard or custom attributes beyond the module's built-in required, immutable, verified `email` attribute. |
| `advanced_security_mode` | `"OFF"` | Adaptive, risk-based authentication: `OFF`, `AUDIT`, or `ENFORCED`. |
| `lambda_config` | `{}` | Cognito Lambda triggers (`pre_sign_up`, `post_confirmation`, `pre_authentication`, `post_authentication`, `custom_message`, `pre_token_generation`, `user_migration`), each a caller-owned Lambda function ARN. |
| `email_configuration` | `null` | A custom SES-backed email sender in place of the Cognito default sender. |

Outputs of 0.1.1:

| 0.1.x output | 1.0.0 equivalent |
| --- | --- |
| `user_pool` | `user_pool`, kept in its exact shape (`id`, `arn`, `endpoint`). |
| `client_ids` | `client_ids`, kept in its exact shape. |
| `resource_server_scope_identifiers` | `resource_server_scope_identifiers`, kept in its exact shape. |
| `replication_status` | **Removed, with no replacement.** It only ever reported `{ managed_by_terraform = false, status = "blocked-provider-support" }` — a constant, not a real status — because Terraform-managed MRR was never implemented. Nothing meaningful is lost. |

New in 1.0.0: the output `advanced_security_mode`, reporting the mode the pool was created with.

A 0.1.x call and its 1.0.0 rewrite, for a consumer whose block is `module "users"`:

```hcl
# 0.1.1
module "users" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=v0.1.1"

  name                = "example-users"
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "ON"

  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }

  # Always false in practice: the module rejected any other value.
  replication = { enabled = false }
}

# 1.0.0
module "users" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=<commit-sha>" # v1.0.0

  name                = "example-users"
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "ON"

  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }

  # replication is gone; there is nothing to replace it with here.
}
```

If your 0.1.x call referenced `module.users.replication_status`, delete that reference; there is no replacement output.

## State addresses

**No resource address changed. This upgrade needs no `moved` blocks and no state migration for any consumer that already avoided the dead `replication` input.** For a consumer block named `module.users`:

| 0.1.1 address | 1.0.0 address |
| --- | --- |
| `module.users.aws_cognito_user_pool.this` | `module.users.aws_cognito_user_pool.this` (unchanged) |
| `module.users.aws_cognito_resource_server.this["<key>"]` | `module.users.aws_cognito_resource_server.this["<key>"]` (unchanged) |
| `module.users.aws_cognito_user_pool_client.this["<key>"]` | `module.users.aws_cognito_user_pool_client.this["<key>"]` (unchanged) |

This is the module's main advantage over the platform's other v1 upgrades: because `replication` never took effect for any working configuration, removing it cannot change what AWS creates, and nothing else in the interface changed shape or address.

## Procedure

1. Pin the 1.0.0 release: copy the commit SHA of tag `v1.0.0` into `?ref=<commit-sha>` and put the tag in a trailing comment.
2. Delete `replication` from your module block, if present, and delete any reference to `replication_status`.
3. Optionally adopt the new inputs (`schema_attributes`, `advanced_security_mode`, `lambda_config`, `email_configuration`); none is required.
4. Run `terraform init -upgrade` to fetch the new module source, then `terraform plan`.
5. Verify the plan shows no changes (or, if you also changed `password_policy.password_history_size` or a new optional input, exactly the change you intended). There must be no replacement or recreation of `aws_cognito_user_pool.this`, `aws_cognito_resource_server.this`, or `aws_cognito_user_pool_client.this`.
6. Apply.
