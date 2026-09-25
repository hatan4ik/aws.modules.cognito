# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Consumers pin the commit SHA of a release tag; see [Versioning and releases](README.md#versioning-and-releases).

## [Unreleased]

## [1.0.0] - 2026-09-25

Breaking release. One module call still provisions one Cognito user pool. [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md) maps every 0.1.x input and output to its replacement; resource addresses are unchanged, so this upgrade needs no `moved` blocks and no state migration for any consumer that already avoided the dead `replication` input.

### Added

- `schema_attributes`: additional standard or custom attributes beyond the module's built-in required, immutable, verified `email` attribute, with plan-time validation of the attribute data type and of the mutable/required combination Cognito accepts.
- `advanced_security_mode`: adaptive, risk-based authentication (`OFF`, `AUDIT`, `ENFORCED`), defaulting to `OFF`.
- `lambda_config`: Cognito Lambda triggers (`pre_sign_up`, `post_confirmation`, `pre_authentication`, `post_authentication`, `custom_message`, `pre_token_generation`, `user_migration`), each validated as a Lambda function ARN.
- `email_configuration`: a custom SES-backed email sender, validated as a verified SES identity ARN, switching `email_sending_account` to `DEVELOPER`.
- `password_policy.password_history_size` (optional, 0–24).
- Output `advanced_security_mode`.
- Examples `minimal`, `web-app-with-scopes`, `production-features`, and `multiple-pools`.
- Mock-provider contract tests in `tests/` covering secure defaults, every new feature, and every validation via `expect_failures`.
- Credential-driven integration suite `smoke` in `tests/integration/`, a `make integration-smoke` target, a dispatch-only `integration` workflow that assumes a role through GitHub OIDC from the protected `integration` environment, and the IAM trust and permissions documents the role needs.
- `docs/DESIGN.md`, `docs/UPGRADE-1.0.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, the `Makefile` quality gate, pre-commit, tflint, and terraform-docs configuration, Dependabot, issue and pull request templates, and the `module-release` workflow.
- CI runs the shared `terraform-quality` workflow over the root and every example, with a docs drift check.

### Changed

- The AWS provider constraint is `>= 6.35.0, < 7.0.0` (unchanged from 0.1.1, restated for clarity alongside the new Terraform provider requirement).

### Removed

- **Breaking:** the top-level input `replication` and the `mrr_provider_capability` guard. The input could never be validly set to anything but its own default (`{ enabled = false }`); a precondition rejected every other value. Multi-Region user pool replication remains a roadmap item pending AWS provider support for `CreateUserPoolReplica`/`UpdateUserPoolReplica`, documented in [docs/DESIGN.md](docs/DESIGN.md) instead of represented by a dead input.
- **Breaking:** the output `replication_status`, which only ever reported the constant `{ managed_by_terraform = false, status = "blocked-provider-support" }`. No replacement; nothing meaningful is lost.

## [0.1.1] - 2026-09-22

### Added

- Generated module reference (inputs and outputs tables) in the README.

## [0.1.0] - 2026-09-22

### Added

- Versioned Cognito user-pool module: verified-email sign-in, a caller-declared password policy, software-token MFA, OAuth authorization-code clients, typed custom resource-server scopes, and a `replication` input reserved for future Multi-Region support.

[Unreleased]: https://github.com/hatan4ik/aws.modules.cognito/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/hatan4ik/aws.modules.cognito/compare/v0.1.1...v1.0.0
[0.1.1]: https://github.com/hatan4ik/aws.modules.cognito/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/hatan4ik/aws.modules.cognito/releases/tag/v0.1.0
