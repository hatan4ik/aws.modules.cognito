locals {
  # These tags identify the module's single responsibility without duplicating caller-owned allocation tags.
  common_tags = merge(var.tags, {
    Name      = var.name
    Component = "cognito-user-pool"
  })

  # The type of var.lambda_config is the single list of supported triggers;
  # this strips the unset ones so an all-null object renders no block at all.
  lambda_config = { for trigger, arn in var.lambda_config : trigger => arn if arn != null }
}
