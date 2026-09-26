# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.x | Yes. Security fixes and functional fixes on the latest minor release. |
| 0.1.x | Security fixes only, until 2026-12-31. Upgrade with [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md). |
| Unreleased `main` | Not supported for production use. |

## Reporting a vulnerability

Use GitHub private vulnerability reporting on this repository: open the Security tab and choose "Report a vulnerability". Do not open a public issue, pull request, or discussion for a security problem.

Include the module version or commit SHA, the inputs that reproduce the problem, the resulting plan, and the impact you see. Redact account IDs, ARNs, and Lambda function names.

## What counts

- A module default that weakens security: MFA configurable off, a password policy that skips a character class, deletion protection or advanced security silently disabled, a client using an implicit or client-credentials flow.
- A client secret, or any credential material, appearing in plan output, in an output, or in a log line the module produces.
- A validation bypass: an input the module claims to reject at plan time (a non-HTTPS callback URL, an undeclared OAuth scope, a malformed Lambda ARN, a non-SES email source) that reaches the provider.
- A scope bypass: a client obtaining an `allowed_oauth_scopes` entry that is neither a standard OIDC scope nor a scope declared on a resource server the pool actually has.
- A dependency problem in the release pipeline that could publish unverified code.

Findings in your own inputs (for example a Lambda function you chose to grant broad permissions) or in AWS services themselves are out of scope here; report the latter to AWS.

## Response

We acknowledge a report within 5 business days and keep you informed while we confirm, fix, and release. A fix ships as a patch release of every supported line with a `CHANGELOG.md` entry that credits the reporter unless they ask otherwise. Please give us a reasonable window before disclosing publicly.

## Security design

The module is secure by default: MFA is `ON` or `OPTIONAL` only, the password policy requires every character class with caller-declared numeric bounds, every client is authorization-code only with HTTPS-validated callback and logout URLs, client secrets are never an output, OAuth scopes are checked against the declared resource servers at plan time, advanced security defaults `OFF` as a deliberate opt-in, Lambda triggers and the email sender are validated ARNs the caller owns, and no data sources are used. Every claim is enforced by a validation, a precondition, or a `terraform test` case behind it. The full description is in the [Security model](README.md#security-model) section of the README, and the reasoning in [docs/DESIGN.md](docs/DESIGN.md).
