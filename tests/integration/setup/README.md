# Integration fixture

The only disposable prerequisite the integration suites in the parent
directory need: a random suffix, so concurrent runs never collide on the
Cognito user-pool name under test. `terraform test` creates it in the
caller's own account before the module under test and destroys it
afterwards. It is not a deployable pattern and is excluded from policy scans
(see `.checkov.yml` and `trivy.yaml` at the repository root).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0, < 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6.0, < 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_suffix"></a> [suffix](#output\_suffix) | Random hex suffix for the disposable pool name. |
<!-- END_TF_DOCS -->
