output "user_pool" {
  description = "Primary user-pool identifiers required by application token validation and supported Cognito configuration."
  value = {
    id       = aws_cognito_user_pool.this.id
    arn      = aws_cognito_user_pool.this.arn
    endpoint = aws_cognito_user_pool.this.endpoint
  }
}

output "client_ids" {
  description = "Stable application-client key to user-pool client ID mapping. Client secrets are deliberately not output."
  value       = { for key, client in aws_cognito_user_pool_client.this : key => client.id }
}

output "resource_server_scope_identifiers" {
  description = "Stable custom resource-server scope identifiers for API authorization configuration."
  value       = { for key, server in aws_cognito_resource_server.this : key => server.scope_identifiers }
}

output "replication_status" {
  description = "Explicit indication that MRR must remain blocked until a provider-backed resource supports the AWS APIs."
  value = {
    managed_by_terraform = false
    status               = "blocked-provider-support"
  }
}
