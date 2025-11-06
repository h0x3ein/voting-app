resource "google_compute_instance" "vm" {
  name         = var.name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    # 🚫 No public IP (IAP-only)
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Install redis-tools automatically
  metadata_startup_script = var.startup_script

  # Ensure redis-proxy tag is always present
  tags = concat(var.tags, ["redis-proxy"])
}