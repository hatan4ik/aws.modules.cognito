output "user_pool" {
  description = "Primary user-pool identifiers."
  value       = module.users.user_pool
}

output "advanced_security_mode" {
  description = "The advanced security mode this pool was created with."
  value       = module.users.advanced_security_mode
}
