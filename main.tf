resource "proxmox_vm_qemu" "stattracker" {
  name               = var.vm_name
  target_node        = var.pm_node
  agent              = 1
  memory             = var.vm_memory
  scsihw             = "virtio-scsi-single"
  os_type            = "cloud-init"
  pool               = var.pm_pool != "" ? var.pm_pool : null
  vm_state           = "running"
  start_at_node_boot = true
  boot               = "order=scsi0"
  clone              = var.pm_template

  startup_shutdown {
    order            = 1
    startup_delay    = 60
    shutdown_timeout = 30
  }

  sshkeys   = var.ssh_key_file != "" ? file(var.ssh_key_file) : ""
  ciupgrade = true

  ipconfig0 = "ip=dhcp"
  skip_ipv6 = true

  ciuser     = var.ci_user
  cipassword = var.ci_password

  serial {
    id = 0
  }

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.pm_storage
          size    = var.vm_disk_size
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.pm_storage
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.pm_bridge
  }

  # Cloud-init user-data que instala y configura todo
  cicustom = "user=local:snippets/stattracker-cloud-init.yml"

  # Fuerza re-creacion si cambia el cloud-init
  lifecycle {
    ignore_changes = [
      sshkeys,
      cicustom,
    ]
  }
}
