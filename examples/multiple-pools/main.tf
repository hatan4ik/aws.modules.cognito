provider "aws" {
  region = var.region
}

# One module call is one user pool. A fleet is a for_each over the module
# block, so each environment keeps its own plan, its own validation errors,
# and its own lifecycle.
module "pool" {
  source   = "../../"
  for_each = var.pools

  name                = each.value.name
  feature_plan        = "ESSENTIALS"
  deletion_protection = each.value.deletion_protection
  mfa_configuration   = each.value.mfa_configuration

  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }

  tags = {
    Environment = each.key
  }
}
