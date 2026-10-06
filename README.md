# aws.modules.cognito

Provisions one Amazon Cognito user pool per root-module call: verified-email sign-in, a strong caller-declared password policy, software-token MFA that is always on or optional (never off), OAuth authorization-code clients, and typed custom resource-server scopes. Additional standard or custom schema attributes, advanced (adaptive, risk-based) security, Lambda triggers, and a custom SES-backed email sender are all optional and default to the secure, low-surface behaviour. The separate `modules/multi-region-replication` composition adopts an eligible existing pool into AWS-native MRR with an inactive-by-default replica and explicit activation gates. Requires Terraform >= 1.7; the root uses AWS provider >= 6.35, < 7 and the MRR composition uses AWSCC >= 1.92, < 2.

## Why this module

What you get from `name`, `feature_plan`, `deletion_protection`, `mfa_configuration`, and `password_policy`, without setting anything else:

- Verified-email sign-in with no weak defaults. Sign-in is by case-insensitive verified email; the password policy has no built-in numbers, so the caller states a real minimum length and temporary-password validity rather than inheriting a value nobody chose. Every character class is required.
- MFA that cannot be turned off. `mfa_configuration` accepts `ON` or `OPTIONAL` only; software-token MFA is enabled either way. A module that let a caller set `OFF` would make the least-secure choice one input away.
- Client secrets never leave the module. `client_ids` outputs the client ID, never the secret; a caller that needs the secret reads it from the provider's own state-free mechanism, not from this module's outputs.
- HTTPS-only client URLs. Every `clients` entry's callback and logout URLs are validated at plan time to start with `https://`, so a plaintext redirect fails before apply, not in a browser.
- Typed custom scopes, not free-text strings. `resource_servers` declares scopes as a map with descriptions; a client's `allowed_oauth_scopes` is checked against the resource servers actually declared, so a typo in a scope name fails at plan time with the client and scope named in the message.
- Advanced security off by default. `advanced_security_mode` defaults to `OFF`; adaptive authentication has cost and behavioural implications, so turning it on is a deliberate `ENFORCED` or `AUDIT` declaration, not something a caller inherits by using the module.
- Everything else stays out of the way until asked for. `schema_attributes`, `lambda_config`, and `email_configuration` are optional maps and objects that default to empty or `null`; none of them changes the rendered pool unless populated.

## Quick start

```hcl
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
}
```

This is [`examples/minimal`](examples/minimal): a verified-email pool with a 14-character password minimum, a 7-day temporary-password window, MFA required, and deletion protection active. No clients and no resource servers exist until declared.

## Architecture

The root has one responsibility — one Cognito user pool per call. MRR is a separate lifecycle and provider boundary:

```text
root (one user pool)
├── main.tf       aws_cognito_user_pool.this, aws_cognito_resource_server.this (for_each), aws_cognito_user_pool_client.this (for_each)
├── locals.tf     Tag computation, Lambda-trigger map with nulls stripped
├── variables.tf  Every input, its type, and its plan-time validation
└── outputs.tf    user_pool, client_ids, resource_server_scope_identifiers
modules/multi-region-replication  adopt an eligible pool into one inactive-by-default native replica
```

A fleet of pools is a `for_each` over the module block, shown in [`examples/multiple-pools`](examples/multiple-pools); the module itself never creates more than one pool.

## Usage patterns

| Example | What it shows |
| --- | --- |
| [`examples/minimal`](examples/minimal) | Just `name`, `feature_plan = "ESSENTIALS"`, `deletion_protection = true`, `mfa_configuration = "ON"`, and a `password_policy`. No clients, no resource servers. |
| [`examples/web-app-with-scopes`](examples/web-app-with-scopes) | One resource server with two custom scopes; one authorization-code client using a standard OIDC scope and a custom scope; `generate_secret = false` for a browser single-page application. |
| [`examples/production-features`](examples/production-features) | `feature_plan = "PLUS"`, `advanced_security_mode = "ENFORCED"`, `schema_attributes` with the required standard `name` attribute and an immutable, optional `custom:` attribute, `lambda_config` with `pre_sign_up` and `post_confirmation`, and `email_configuration` backed by an SES identity. |
| [`examples/multiple-pools`](examples/multiple-pools) | A `variable "pools"` map and `module "pool" { for_each = var.pools ... }`, one pool per environment with per-pool `deletion_protection` and `mfa_configuration`. |
| [`examples/multi-region-replica`](examples/multi-region-replica) | AWS-native MRR with explicit primary/secondary AWSCC providers, matching multi-Region KMS-key evidence, and a separate activation gate. |

## Security model

Identity and credentials

- `mfa_configuration` accepts `ON` or `OPTIONAL` only; there is no way to configure this module with MFA off. Software-token MFA is enabled in either case.
- The password policy has no default numbers: `minimum_length` (8–99), `temporary_password_validity_days` (1–365), and an optional `password_history_size` (0–24) are all caller-declared. Every character class (lowercase, uppercase, numbers, symbols) is always required.
- Account recovery is by verified email only, and email updates require re-verification before they take effect (`user_attribute_update_settings`).

Clients

- Every client is an OAuth authorization-code client (`allowed_oauth_flows = ["code"]`); implicit and client-credentials flows are not exposed.
- Token lifetimes have fixed units: `access_token_validity` and `id_token_validity` are minutes (5–1440), `refresh_token_validity` is days (1–3650). Values outside Cognito's own bounds, or fractional values, fail at plan time.
- Callback and logout URLs are validated at plan time to be `https://`; a plaintext URL never reaches AWS.
- `generate_secret` is explicit per client, so a public browser client (no secret) and a confidential server-side client (a secret) are both first-class, distinguishable choices.
- `prevent_user_existence_errors = "ENABLED"` on every client, so authentication errors do not reveal whether an account exists.
- Client secrets are never an output of this module.

Scopes

- `resource_servers` scopes are typed (a map with a description), and a client's `allowed_oauth_scopes` is checked by a `lifecycle.precondition` against the standard OIDC scopes and the resource servers actually declared; an undeclared scope fails the plan with the client and scope named.

Advanced security, triggers, and email

- `advanced_security_mode` defaults to `OFF`. Turning on adaptive, risk-based authentication (`AUDIT` or `ENFORCED`) is a deliberate declaration, not a module default, because it changes sign-in behaviour and cost. It is a Plus-tier feature, so a precondition fails the plan unless `feature_plan = "PLUS"`.
- `schema_attributes` may mark only OIDC standard attributes (`name`, `given_name`, `phone_number`, ...) as `required`; Cognito does not allow a required custom attribute, so one fails at plan time. Enforce presence of a custom attribute in a `pre_sign_up` trigger instead.
- `verification_email` sets the subject and body of the code-verification email (the `{####}` placeholder is required); unset, it keeps the module's default text. The confirmation method stays `CONFIRM_WITH_CODE`.
- `lambda_config` accepts only ARNs matching the Lambda function ARN shape; the caller owns the function and its resource-based policy granting Cognito permission to invoke it. This module grants no Lambda permissions.
- `email_configuration` is optional; when unset the pool uses the Cognito default sender (fine for low volume, rate-limited, unbranded). When set, `email_sending_account` switches to `DEVELOPER` and the caller-supplied SES identity ARN is validated at plan time to be an SES identity ARN.

## Operating notes

### Lambda trigger failures are invisible to Terraform

`lambda_config` validates only the *shape* of each ARN. A well-formed ARN that points at a function that does not exist, a function in another Region, or a function whose resource-based policy does not allow `lambda:InvokeFunction` for the principal `cognito-idp.amazonaws.com` passes plan **and** apply cleanly. The pool is then broken for every user who reaches that trigger: sign-up fails if `pre_sign_up` or `post_confirmation` is broken, every sign-in fails if `pre_authentication`, `post_authentication`, `pre_token_generation`, or `user_migration` is broken, and verification emails stop if `custom_message` is broken. This module cannot check another resource's permissions without a data-source read, which it deliberately does not perform, so detection is the operator's job:

- Before apply, confirm each function exists and grants Cognito invoke permission scoped to this pool: `aws lambda get-policy --function-name <arn>` must show `Principal: cognito-idp.amazonaws.com` with `AWS:SourceArn` equal to the pool ARN (`user_pool.arn` output). Create that permission with `aws_lambda_permission` in the root that owns the function.
- After apply, exercise each configured flow once (a test sign-up and sign-in). Client SDKs surface trigger failures as `UnexpectedLambdaException`, `InvalidLambdaResponseException`, or `UserLambdaValidationException` rather than a Terraform error.
- In CloudWatch, alarm on the function's own `Errors` metric and on its `Invocations` metric staying at zero while sign-up or sign-in traffic exists (a missing permission or nonexistent function means Cognito never invokes it, so the function's log group stays empty). Cognito's `AWS/Cognito` metrics (`SignUpSuccesses`, `SignInSuccesses`, `TokenRefreshSuccesses`) dropping to zero after a change to `lambda_config` is the pool-side signal.

### Service quotas

Cognito limits that bound how this module can be used (defaults per [Quotas in Amazon Cognito](https://docs.aws.amazon.com/cognito/latest/developerguide/quotas.html); check your account in Service Quotas):

| Resource | Default | Adjustable | Relevant input |
| --- | --- | --- | --- |
| Custom attributes per user pool | 50 | No | `schema_attributes` (custom attributes also can never be removed once created) |
| App clients per user pool | 1,000 | Yes (up to 10,000) | `clients` |
| Resource servers per user pool | 25 | Yes (up to 300) | `resource_servers` |
| Scopes per resource server | 100 | No | `resource_servers[*].scopes` |
| Scopes per app client | 50 | No | `clients[*].allowed_oauth_scopes` |
| Callback / logout URLs per app client | 100 each | No | `clients[*].callback_urls`, `logout_urls` |

These are not validated at plan time; exceeding one fails at apply with `LimitExceededException`.

### Multi-Region replication is constrained continuity, not full active-active

`modules/multi-region-replication` creates AWS-native Cognito MRR; it does not implement the earlier event-driven user-copy workaround. AWS keeps the primary authoritative for sign-up, password reset, profile writes, and other administrative changes, while the secondary handles a supported subset of authentication operations after activation. Replication is eventually consistent, one secondary is permitted, and TOTP MFA is not supported in that secondary.

The composition therefore defaults to `INACTIVE`, requires reviewed evidence before activation, and blocks activation entirely when the primary reports `mfa_configuration = "ON"`. With `OPTIONAL`, users enrolled in TOTP are still unable to use the secondary; the activation gate forces the platform owner to accept and document that limitation. Application/API routing and Cognito domain health-check routing remain environment concerns and must be exercised in the failover runbook.

## Design principles

- **Single responsibility.** One resource concept — a Cognito user pool — is the module's entire scope. Clients and resource servers are `for_each` children of that one pool, not independent concerns.
- **Open/closed.** New pool behaviour arrives as data on existing inputs: another key in `clients`, another scope in `resource_servers`, another entry in `schema_attributes` or `lambda_config`. No caller needs the module edited to add a client, a scope, or an attribute.
- **Liskov substitution.** Every `clients` entry renders identically regardless of key or count; a caller that adds a second client does not change how the first one behaves. `email_configuration = null` and a populated `email_configuration` differ only in which sender Cognito uses, not in the shape of `user_pool`, `client_ids`, or any other output.
- **Interface segregation.** A caller who wants only the minimal pool sets five required inputs and touches nothing else; `schema_attributes`, `advanced_security_mode`, `lambda_config`, and `email_configuration` are independent optional inputs that a minimal caller never has to reason about.
- **Dependency inversion.** The module depends on identifiers the caller supplies (a Lambda ARN, an SES identity ARN), never on how those resources were built or which module produced them, and performs no data-source reads.

The full rationale, including why the v0.1.x design was replaced, is in [docs/DESIGN.md](docs/DESIGN.md).

## Compatibility and scope

- Terraform `>= 1.7.0, < 2.0.0`. AWS provider `>= 6.35.0, < 7.0.0`.
- The root owns one Cognito user pool, its authorization-code clients, and custom resource-server scopes. Identity providers (SAML, OIDC federation) and a hosted-UI domain are not created here.
- Native MRR is implemented as the separate `modules/multi-region-replication` composition because it has a different lifecycle and needs primary and secondary AWSCC provider configurations. It can adopt only an already eligible pool whose multi-Region KMS key configuration has been completed and verified; the current AWS provider cannot configure that primary-pool setting.
- Nothing in the v1 interface is scheduled to change. Additions arrive as optional inputs and outputs.

## Versioning and releases

Releases follow semantic versioning: incompatible interface changes bump the major version, new optional inputs and outputs bump the minor version, fixes bump the patch version. Every release is a signed annotated tag `vX.Y.Z`.

Pin the full commit SHA of the release tag and record the tag in a comment, so the source cannot move under you:

```hcl
module "users" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=<commit-sha>" # v1.0.0
}
```

The `module-release` workflow publishes an immutable GitHub release only from a GitHub-verified, signed, annotated semantic-version tag that points at the merged `main` revision; lightweight or unsigned tags are rejected before anything is published. With a GitHub-associated GPG or SSH signing key configured:

```bash
git fetch origin
git tag -s vX.Y.Z <commit> -m "vX.Y.Z"
git push origin vX.Y.Z
gh workflow run module-release.yml --ref vX.Y.Z -f release_tag=vX.Y.Z
```

Dispatch from the tag, never from `main`: the workflow verifies that the tag points at the revision it checked out, and a maintenance release for an older line (for example a 0.1.x fix after 1.0.0 landed on `main`) is cut from that line's commit.

Upgrading from 0.1.x: read [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md) for the input and output mapping. No resource address changed, so this upgrade needs no `moved` blocks and no state migration for any consumer that already avoided the dead `replication` input. All changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Contributing

Development setup, the local quality gate, the test-first workflow, and the release process are described in [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md).

## License

Apache-2.0. See [LICENSE](LICENSE).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.35.0, < 7.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cognito_resource_server.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_security_mode"></a> [advanced\_security\_mode](#input\_advanced\_security\_mode) | Cognito advanced (adaptive, risk-based) security: OFF, AUDIT, or ENFORCED. Costs more and changes sign-in behaviour, so it defaults off. | `string` | `"OFF"` | no |
| <a name="input_clients"></a> [clients](#input\_clients) | Stable client-keyed OAuth authorization-code clients. Callback and logout URLs must be reviewed application endpoints. Token validity units are fixed by the module: access\_token\_validity and id\_token\_validity are in MINUTES (whole numbers, 5-1440, i.e. 5 minutes to 1 day); refresh\_token\_validity is in DAYS (whole numbers, 1-3650, i.e. 1 day to 10 years). These are the Cognito service bounds. | <pre>map(object({<br/>    callback_urls          = set(string)<br/>    logout_urls            = set(string)<br/>    allowed_oauth_scopes   = set(string)<br/>    access_token_validity  = number<br/>    id_token_validity      = number<br/>    refresh_token_validity = number<br/>    generate_secret        = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether AWS Cognito deletion protection remains active for this user pool. | `bool` | n/a | yes |
| <a name="input_email_configuration"></a> [email\_configuration](#input\_email\_configuration) | Custom (SES-backed) email sender. Null keeps the Cognito default sender, which is fine for low-volume or non-production pools but is rate-limited and cannot be branded. | <pre>object({<br/>    source_arn             = string<br/>    from_email_address     = optional(string)<br/>    reply_to_email_address = optional(string)<br/>    configuration_set      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_feature_plan"></a> [feature\_plan](#input\_feature\_plan) | Cognito feature plan (user pool tier): ESSENTIALS or PLUS. LITE is rejected because it cannot meet this module's security contract (ALLOW\_USER\_AUTH needs ESSENTIALS or higher). PLUS is required for advanced\_security\_mode AUDIT or ENFORCED. | `string` | n/a | yes |
| <a name="input_lambda_config"></a> [lambda\_config](#input\_lambda\_config) | Cognito Lambda triggers this module supports, by trigger name. Each value is a Lambda function ARN; the caller owns the function and its permission to be invoked by Cognito. | <pre>object({<br/>    pre_sign_up          = optional(string)<br/>    post_confirmation    = optional(string)<br/>    pre_authentication   = optional(string)<br/>    post_authentication  = optional(string)<br/>    custom_message       = optional(string)<br/>    pre_token_generation = optional(string)<br/>    user_migration       = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | Cognito MFA policy. Software-token MFA is enabled for either permitted secure value. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Lowercase Cognito user-pool name used in resource names and tags. | `string` | n/a | yes |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Explicit password-policy contract. Numeric values are product/security decisions, not module defaults. | <pre>object({<br/>    minimum_length                   = number<br/>    temporary_password_validity_days = number<br/>    password_history_size            = optional(number)<br/>  })</pre> | n/a | yes |
| <a name="input_resource_servers"></a> [resource\_servers](#input\_resource\_servers) | Stable resource-server keyed custom OAuth scope contracts. | <pre>map(object({<br/>    identifier = string<br/>    name       = string<br/>    scopes = map(object({<br/>      description = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_schema_attributes"></a> [schema\_attributes](#input\_schema\_attributes) | Additional standard or custom attributes beyond the module's built-in required, immutable, verified email attribute. Keys are attribute names (custom attributes are given the custom: prefix automatically by Cognito when name does not already have one). | <pre>map(object({<br/>    attribute_data_type      = string<br/>    mutable                  = optional(bool, true)<br/>    required                 = optional(bool, false)<br/>    developer_only_attribute = optional(bool, false)<br/>    string_constraints = optional(object({<br/>      min_length = optional(number)<br/>      max_length = optional(number)<br/>    }))<br/>    number_constraints = optional(object({<br/>      min_value = optional(number)<br/>      max_value = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional required allocation and ownership tags. Name and Component tags are computed by the module. | `map(string)` | `{}` | no |
| <a name="input_verification_email"></a> [verification\_email](#input\_verification\_email) | Subject and body of the email Cognito sends with the sign-up/attribute verification code. The message must contain the {####} code placeholder. Omitting either field keeps the module's v1.0 text, so existing callers see no change. Branded copy is typically paired with email\_configuration (an SES sender). | <pre>object({<br/>    subject = optional(string, "Verify your sign-in")<br/>    message = optional(string, "Your verification code is {####}.")<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Stable application-client key to user-pool client ID mapping. Client secrets are deliberately not output. |
| <a name="output_resource_server_scope_identifiers"></a> [resource\_server\_scope\_identifiers](#output\_resource\_server\_scope\_identifiers) | Stable custom resource-server scope identifiers for API authorization configuration. |
| <a name="output_user_pool"></a> [user\_pool](#output\_user\_pool) | Primary user-pool identifiers required by application token validation and supported Cognito configuration. |
<!-- END_TF_DOCS -->
