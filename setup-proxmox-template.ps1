# ============================================================
# Script de preparacion de Proxmox para StatTracker
# Ejecutar en el servidor Proxmox (no en tu PC Windows)
# ============================================================

# 1. Descargar template cloud-init Debian 12
wget -O /var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2 `
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# 2. Crear VM template
qm create 9000 --memory 2048 --cores 2 --name debian-12-template --net0 virtio,bridge=vmbr0

# 3. Importar disco
qm importdisk 9000 /var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2 local-lvm

# 4. Adjuntar disco como SCSI
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# 5. Crear disco cloud-init
qm set 9000 --ide0 local-lvm:cloudinit

# 6. Configurar boot y serial
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket
qm set 9000 --vga serial0

# 7. Convertir en template
qm template 9000

# 8. Crear directorio de snippets si no existe
mkdir -p /var/lib/vz/snippets

# El archivo stattracker-cloud-init.yml debe copiarse aqui manualmente:
# scp stattracker-cloud-init.yml root@TU_PROXMOX:/var/lib/vz/snippets/
