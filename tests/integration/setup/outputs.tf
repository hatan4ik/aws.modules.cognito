output "suffix" {
  description = "Random hex suffix for the disposable pool name."
  value       = random_id.suffix.hex
}
