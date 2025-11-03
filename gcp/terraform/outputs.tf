output "eso_private_key" {
  description = "The ESO service account private key from the IAM module."
  value       = module.iam.eso_private_key
  sensitive   = true
}