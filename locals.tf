locals {
  # These tags identify the module's single responsibility without duplicating caller-owned allocation tags.
  common_tags = merge(var.tags, {
    Name      = var.name
    Component = "cognito-user-pool"
  })

  lambda_config = {
    for key, value in {
      pre_sign_up          = var.lambda_config.pre_sign_up
      post_confirmation    = var.lambda_config.post_confirmation
      pre_authentication   = var.lambda_config.pre_authentication
      post_authentication  = var.lambda_config.post_authentication
      custom_message       = var.lambda_config.custom_message
      pre_token_generation = var.lambda_config.pre_token_generation
      user_migration       = var.lambda_config.user_migration
    } : key => value if value != null
  }
}
