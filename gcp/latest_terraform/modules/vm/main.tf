resource "google_compute_instance" "vm" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  network_interface {
    network = var.network
  }
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  tags = ["redis-proxy"]
}