locals {
  # These tags identify the module's single responsibility without duplicating caller-owned allocation tags.
  common_tags = merge(var.tags, {
    Name      = var.name
    Component = "cognito-user-pool"
  })
}
