###############################################
# 📤 Outputs
###############################################

output "secret_names" {
  description = "The names of the created secrets."
  value = [
    google_secret_manager_secret.mysql_password.secret_id,
    google_secret_manager_secret.mysql_root_password.secret_id,
    google_secret_manager_secret.mysql_user.secret_id,
  ]
}

