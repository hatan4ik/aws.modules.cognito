# Design: aws.modules.cognito v1

Status: accepted 2026-09-25. Supersedes v0.1.x.

## Purpose

`aws.modules.cognito` provisions **one** Amazon Cognito user pool per module call: verified-email sign-in, a strong password policy, software-token MFA, OAuth authorization-code clients, and typed custom resource-server scopes. It is secure by default and explicit by declaration. It deliberately does not create identity providers, hosted-UI domains, or a second (replica) pool.

## Why the v0.1.x design was replaced

| v0.1.x behaviour | Problem | v1 decision |
|---|---|---|
| `replication` input that is *always* rejected by a precondition whenever `enabled = true`. | An input that can never be validly set to anything but its own default is dead weight (YAGNI) — it documents an unbuilt feature as if it were a real, merely-restricted one. | Removed. MRR stays a roadmap item, stated in the README, with no input pretending otherwise. |
| One hard-coded `email` schema attribute; no way to add another standard or custom attribute. | Real applications need at least one more attribute (`name`, `preferred_username`, a custom claim) and could not add one without forking the module. | `schema_attributes` — an ordered map of additional attributes: `email` remains the one built-in required, immutable, verified attributes. |
| No advanced security, no Lambda triggers, no custom email/SMS sender. | Common production requirements (risk-based adaptive authentication, custom sign-up validation, a branded email sender) had no way in. | Optional `advanced_security_mode`, `lambda_config` (typed trigger map), `email_configuration`. |
| Consumed by `aws.modules.ecs` via a **tag** (`?ref=v0.1.0`), not a commit SHA — the one place in the whole platform that violates its own consumer rule. | A tag can be force-moved; only a commit SHA is immutable. | No module-side fix possible (it's a consumer error), but the v1.0.0 upgrade guide calls it out explicitly so `aws.modules.ecs`'s own uplift corrects it. |
| No examples, no CI standards, no integration suite, no release pipeline. | Not consumable as a product; every release was tagged by hand. | Full example set, standards, integration suite (this session's playbook pattern), and a working `module-release.yml`. |

## Interface (summary)

Unchanged from v0.1.x and kept because it was already right: `name`, `feature_plan` (ESSENTIALS | PLUS), `deletion_protection`, `mfa_configuration` (ON | OPTIONAL), `password_policy`, `clients` (typed OAuth authorization-code clients, HTTPS-only URLs, no secrets ever output), `resource_servers` (typed custom scopes), `tags`.

New in v1: `schema_attributes` (optional map, additional standard or custom attributes beyond the built-in `email`), `advanced_security_mode` (optional, OFF | AUDIT | ENFORCED, default OFF), `lambda_config` (optional map of the Cognito trigger names this module supports: `pre_sign_up`, `post_confirmation`, `pre_token_generation`, `custom_message`, each a Lambda ARN), `email_configuration` (optional; SES-based custom sender, defaulting to the Cognito default sender when unset).

Removed in v1: `replication` and the `mrr_provider_capability` guard.

## Security defaults

Deletion protection is caller-controlled but always explicit; MFA is ON or OPTIONAL, never OFF; password policy has no weak default (the caller states real numbers); every client is authorization-code with HTTPS callback/logout URLs; client secrets are never an output; advanced security defaults OFF (a caller who wants adaptive auth turns it on deliberately, since it has cost and behavioural implications).

## Testing strategy

Contract tests with `mock_provider`; an integration `smoke` suite that creates and destroys a real minimal pool with one client in the caller's own account; examples for a minimal pool, a pool with clients and resource-server scopes, one using the new schema/lambda/advanced-security inputs, and multiple pools via `for_each`.

## Compatibility

Terraform `>= 1.7.0, < 2.0.0`, AWS provider `>= 6.35.0, < 7.0.0`. Multi-Region user pool replication remains unimplemented pending AWS provider support for `CreateUserPoolReplica`/`UpdateUserPoolReplica`; when that lands it will be a new optional input, not a resurrection of the always-rejecting `replication` field.
