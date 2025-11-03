resource "google_compute_instance" "vm" {
  name         = var.name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  
  allow_stopping_for_update = true  # ✅ <-- Add this line
  
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # Optional: only create public IP if assign_public_ip = true
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = var.startup_script

  tags = var.tags

 
}
