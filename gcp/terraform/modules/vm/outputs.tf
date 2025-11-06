output "vm_name" {
  description = "The name of the created VM"
  value       = google_compute_instance.vm.name
}

output "internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "self_link" {
  description = "Self-link of the VM resource"
  value       = google_compute_instance.vm.self_link
}