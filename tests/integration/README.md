# Integration suites

The suites in this directory apply the module for real in **your** AWS
account and destroy everything afterwards. They complement the contract
tests in `tests/`, which run with `mock_provider`, need no credentials, and
prove the module's interface and rendering, not that AWS accepts it. These
suites prove the latter.

A Cognito user pool needs no VPC, hosted zone, or other infrastructure
prerequisite. The only fixture is a random suffix (`tests/integration/setup`,
a single `random_id` resource) that keeps concurrent runs from colliding on
the pool name; it is created and destroyed by `terraform test` along with the
pool itself, and needs no AWS credentials of its own.

| Suite | What it proves | Needs | Typical time |
| --- | --- | --- | --- |
| `smoke.tftest.hcl` | A minimal `ESSENTIALS` pool with one authorization-code client is accepted by the real API; the pool ID, ARN, and endpoint are well-formed; the client ID is returned; `advanced_security_mode` defaults to `OFF`; the pool and client are deleted at the end of the run. | credentials, region | about a minute |

## Run it in your account

```bash
export AWS_PROFILE=<your profile>   # or AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
export AWS_REGION=<region>
terraform init -backend=false -test-directory=tests/integration
terraform test -test-directory=tests/integration -filter=tests/integration/smoke.tftest.hcl
```

`deletion_protection = false` is required for the suite's pool so that
`terraform test`'s automatic destroy at the end of the run can delete it; a
pool created with `ACTIVE` deletion protection would block that destroy.

The credentials need the permissions in
[`iam/integration-permissions-policy.json`](iam/integration-permissions-policy.json)
(replace `<ACCOUNT_ID>`): `cognito-idp:CreateUserPool`, `DeleteUserPool`,
`UpdateUserPool`, `CreateUserPoolClient`, `DeleteUserPoolClient`,
`UpdateUserPoolClient`, `CreateResourceServer`, `DeleteResourceServer`,
`DescribeUserPool`, `ListUserPools`, `TagResource`, and `UntagResource`,
scoped as tightly as the Cognito API allows. Nothing else is touched.

`terraform test` runs `tests/` only by default, so these suites never run in
the credential-free quality pipeline.

## Run it from GitHub Actions (owner lane)

The `integration` workflow (`.github/workflows/integration.yml`) is
dispatch-only and assumes a role through GitHub OIDC. It reads everything
account-specific from the protected `integration` environment of the
repository, so the code stays universal:

| Environment variable | Meaning |
| --- | --- |
| `AWS_INTEGRATION_ROLE_ARN` | Role the workflow assumes. Trust policy: [`iam/github-oidc-trust-policy.json`](iam/github-oidc-trust-policy.json) with `<OWNER>/<REPO>` set to this repository; permissions: the policy above. |
| `AWS_INTEGRATION_REGION` | Region the pool is created in. |

Dispatch with `gh workflow run integration.yml -f suite=smoke`. Protect the
environment with required reviewers so a run cannot be started from a pull
request by anyone with write access.

For this repository's owner the environment is prepared with the sandbox
region; the role ARN is added once the role exists in the sandbox account,
created through the platform's delivery IAM module with the trust policy
above and the subject
`repo:hatan4ik/aws.modules.cognito:environment:integration`.
