variable "pm_api_url" {
  description = "URL del servidor Proxmox (ej: https://192.168.1.100:8006/api2/json)"
  type        = string
}

variable "pm_api_token_id" {
  description = "ID del API Token de Proxmox (ej: root@pam!terraform)"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Secret del API Token de Proxmox"
  type        = string
  sensitive   = true
}

variable "pm_node" {
  description = "Nombre del nodo Proxmox (ej: pve)"
  type        = string
}

variable "pm_template" {
  description = "Nombre de la plantilla cloud-init (ej: debian-12-template)"
  type        = string
}

variable "pm_pool" {
  description = "Pool de recursos en Proxmox"
  type        = string
  default     = ""
}

variable "pm_storage" {
  description = "Almacenamiento para discos (ej: local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "pm_bridge" {
  description = "Bridge de red (ej: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vm_name" {
  description = "Nombre de la maquina virtual"
  type        = string
  default     = "stattracker"
}

variable "vm_cores" {
  description = "Numero de CPUs"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Tamano del disco en GB"
  type        = string
  default     = "20G"
}

variable "ci_user" {
  description = "Usuario para cloud-init"
  type        = string
  default     = "stattracker"
}

variable "ci_password" {
  description = "ContraseÃ±a para el usuario de cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_key_file" {
  description = "Ruta a la clave publica SSH (ej: ~/.ssh/id_rsa.pub)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "URL del repositorio GitHub de StatTracker"
  type        = string
  default     = "https://github.com/AlvaroPavon/StatTracker"
}

variable "github_branch" {
  description = "Rama del repositorio a desplegar"
  type        = string
  default     = "main"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "proyecto_imc"
}

variable "db_user" {
  description = "Usuario de MySQL"
  type        = string
  default     = "stattracker"
}

variable "db_password" {
  description = "ContraseÃ±a de MySQL"
  type        = string
  sensitive   = true
  default     = "Stattracker2025!"
}

variable "db_root_password" {
  description = "ContraseÃ±a de root para MySQL"
  type        = string
  sensitive   = true
  default     = "MySQLRoot2025!"
}
