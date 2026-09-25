output "user_pool" {
  description = "Primary user-pool identifiers."
  value       = module.users.user_pool
}

output "client_ids" {
  description = "Application-client key to user-pool client ID mapping."
  value       = module.users.client_ids
}

output "resource_server_scope_identifiers" {
  description = "Custom resource-server scope identifiers."
  value       = module.users.resource_server_scope_identifiers
}
