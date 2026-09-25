provider "aws" {
  region = var.region
}

# The smallest working call: verified-email sign-in, a strong password
# policy, and MFA required. No clients and no resource servers; add them
# once an application is ready to authenticate against this pool.
module "users" {
  source = "../../"

  name                = var.name
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "ON"

  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }
}
