output "user_pools" {
  description = "Primary user-pool identifiers keyed by environment."
  value       = { for key, pool in module.pool : key => pool.user_pool }
}
