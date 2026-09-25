provider "aws" {
  region = var.region
}

# A resource server with two custom scopes, and one authorization-code
# client using both a standard OIDC scope and a custom scope.
# generate_secret = false is the public-client pattern for a browser SPA,
# which cannot keep a client secret confidential.
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

  resource_servers = {
    api = {
      identifier = "https://api.${var.name}.example.com"
      name       = "${var.name}-api"
      scopes = {
        "orders.read"  = { description = "Read orders" }
        "orders.write" = { description = "Create and update orders" }
      }
    }
  }

  clients = {
    web = {
      callback_urls = var.callback_urls
      logout_urls   = var.logout_urls
      allowed_oauth_scopes = [
        "openid",
        "https://api.${var.name}.example.com/orders.read",
      ]
      access_token_validity  = 60
      id_token_validity      = 60
      refresh_token_validity = 30
      generate_secret        = false
    }
  }
}
