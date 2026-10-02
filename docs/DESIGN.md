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

New in v1: `schema_attributes` (optional map, additional standard or custom attributes beyond the built-in `email`), `advanced_security_mode` (optional, OFF | AUDIT | ENFORCED, default OFF), `lambda_config` (optional typed object of the Cognito trigger names this module supports: `pre_sign_up`, `post_confirmation`, `pre_authentication`, `post_authentication`, `custom_message`, `pre_token_generation`, `user_migration`, each a Lambda ARN; the object type is the single list of supported triggers), `email_configuration` (optional; SES-based custom sender, defaulting to the Cognito default sender when unset).

Removed in v1: `replication` and the `mrr_provider_capability` guard.

## Post-1.0 audit corrections

A read-only audit after 1.0.0 found plan-time gaps and drift; the decisions taken:

| Finding | Decision |
|---|---|
| `schema_attributes` rejected *required + immutable*, citing a Cognito rule that does not exist (the built-in `email` is exactly that), while accepting *required custom* attributes, which Cognito does reject. | Validation enforces the real rule: only OIDC standard attributes may be `required`. Immutability is unrestricted. |
| `advanced_security_mode = AUDIT/ENFORCED` with `feature_plan = ESSENTIALS` passed plan and failed at apply. | `lifecycle.precondition` on the pool: threat protection requires `PLUS`. |
| Token validity had no stated units and only a `> 0` check. | Units stated in the `clients` description (access/ID minutes, refresh days); ranges 5–1440 and 1–3650, whole numbers, enforced. |
| Lambda trigger names listed three times; the dynamic block read the raw variable, not the normalized local. | The `lambda_config` object type is the one list; validation and the local iterate it, and the dynamic block reads the local. Provider arguments must still be named once in `main.tf`. |
| Verification email subject/body hard-coded with no recorded reason. | No branding or compliance ADR requires fixed text, so it is the optional `verification_email` input, defaulting to the exact 1.0 text. `CONFIRM_WITH_CODE` stays fixed as part of the security floor. |
| Output `advanced_security_mode` echoed the input. | No consumer in the platform or any `aws.modules.*` repository, so it is removed (breaking; next release is a major version). |
| A well-formed trigger ARN for a missing function or one lacking invoke permission passes plan and apply and silently breaks auth flows. | Not checkable without data-source reads, which the module avoids; the failure mode and its detection are documented in the README "Operating notes". |
| Cognito service quotas undocumented. | Documented in the README "Operating notes" (50 custom attributes, 1,000 clients, 25 resource servers, 100 scopes per server, 50 scopes per client). |

## Security defaults

Deletion protection is caller-controlled but always explicit; MFA is ON or OPTIONAL, never OFF; password policy has no weak default (the caller states real numbers); every client is authorization-code with HTTPS callback/logout URLs; client secrets are never an output; advanced security defaults OFF (a caller who wants adaptive auth turns it on deliberately, since it has cost and behavioural implications).

## Testing strategy

Contract tests with `mock_provider`; an integration `smoke` suite that creates and destroys a real minimal pool with one client in the caller's own account; examples for a minimal pool, a pool with clients and resource-server scopes, one using the new schema/lambda/advanced-security inputs, and multiple pools via `for_each`.

## Compatibility

Terraform `>= 1.7.0, < 2.0.0`, AWS provider `>= 6.35.0, < 7.0.0`. Multi-Region user pool replication remains unimplemented pending AWS provider support for `CreateUserPoolReplica`/`UpdateUserPoolReplica`; when that lands it will be a new optional input, not a resurrection of the always-rejecting `replication` field.
