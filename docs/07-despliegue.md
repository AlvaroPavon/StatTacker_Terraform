# Despliegue Paso A Paso

## 1. Preparar Proxmox

Crear o tener un template cloud-init Debian.

Ejemplo:

```bash
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
qm create 9000 --memory 2048 --cores 2 --name debian-12-template
qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide0 local-lvm:cloudinit
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket
qm set 9000 --vga serial0
qm template 9000
```

## 2. Subir Cloud-init A Proxmox

```bash
scp proxmox-snippets/stattracker-cloud-init.yml root@TU_PROXMOX:/var/lib/vz/snippets/stattracker-cloud-init.yml
```

## 3. Configurar Terraform

```bash
cp terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars` con:

- URL API Proxmox.
- Token ID.
- Token secret.
- Nodo.
- Template.
- Password del usuario cloud-init.
- Datos de base de datos.

No subir `terraform.tfvars` a Git.

## 4. Ejecutar Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## 5. Acceder A La Web

```bash
terraform output app_url
```

O en el despliegue actual:

```text
http://192.168.5.34/
```

## 6. Reaplicar Configuracion Con Ansible

Si la VM ya existe y se quiere corregir Apache, MariaDB, CSS o CSP:

```bash
cd ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

## 7. Ejecutar Desde Dentro De La VM

La VM tambien contiene el proyecto:

```bash
ssh stattracker@192.168.5.34
cd /home/stattracker/StatTacker_Terraform
terraform validate
cd ansible
ansible-playbook site.yml --syntax-check
```

## 8. Subir A GitHub

Antes:

```bash
git status --short
```

No debe aparecer:

```text
terraform.tfvars
terraform.tfstate
.terraform/
```

Subida:

```bash
git add .
git commit -m "Document StatTracker infrastructure"
git push origin main
```
