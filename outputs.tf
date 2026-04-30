output "vm_ip_address" {
  description = "Direccion IP de la VM StatTracker"
  value       = proxmox_vm_qemu.stattracker.default_ipv4_address
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = proxmox_vm_qemu.stattracker.name
}

output "vm_id" {
  description = "ID de la VM en Proxmox"
  value       = proxmox_vm_qemu.stattracker.vmid
}

output "ssh_command" {
  description = "Comando para conectar por SSH"
  value       = "ssh ${var.ci_user}@${proxmox_vm_qemu.stattracker.default_ipv4_address}"
}

output "app_url" {
  description = "URL de la aplicacion StatTracker"
  value       = "http://${proxmox_vm_qemu.stattracker.default_ipv4_address}"
}

output "db_connection" {
  description = "Informacion de conexion a la base de datos"
  value = {
    host     = "localhost"
    port     = 3306
    database = var.db_name
    user     = var.db_user
    password = var.db_password
  }
  sensitive = true
}
