# Terraform

## Funcion

Terraform gestiona la VM en Proxmox. Define CPU, memoria, disco, red, cloud-init, arranque automatico y conexion con la API de Proxmox.

## Archivos

| Archivo | Funcion |
| --- | --- |
| `providers.tf` | Declara Terraform y el provider `telmate/proxmox`. |
| `main.tf` | Define la VM `proxmox_vm_qemu.stattracker`. |
| `variables.tf` | Declara variables configurables. |
| `outputs.tf` | Muestra IP, nombre, VMID, URL y SSH. |
| `terraform.tfvars.example` | Plantilla sin secretos para crear `terraform.tfvars`. |
| `.terraform.lock.hcl` | Versiones y checksums del provider. Debe subirse a Git. |

## Variables Principales

| Variable | Descripcion |
| --- | --- |
| `pm_api_url` | URL API de Proxmox. |
| `pm_api_token_id` | ID del token API. |
| `pm_api_token_secret` | Secreto del token API. No subir a Git. |
| `pm_node` | Nodo Proxmox donde se crea la VM. |
| `pm_template` | Template cloud-init usado como base. |
| `pm_storage` | Storage Proxmox para disco. |
| `pm_bridge` | Bridge de red. |
| `vm_name` | Nombre de la VM creada por Terraform. |
| `vm_cores` | Numero de cores. |
| `vm_memory` | RAM en MB. |
| `vm_disk_size` | Tamano del disco. |
| `ci_user` | Usuario creado por cloud-init. |
| `ci_password` | Contrasena del usuario cloud-init. No subir a Git. |

## Arranque Automatico

`main.tf` contiene:

```hcl
start_at_node_boot = true

startup_shutdown {
  order            = 1
  startup_delay    = 60
  shutdown_timeout = 30
}
```

Esto hace que Proxmox arranque la VM automaticamente al arrancar el nodo.

En la VM actual tambien se aplico directamente por API Proxmox:

```text
onboot = 1
startup = order=1,up=60,down=30
```

## Comandos Basicos

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

## Estado Local

No subir a GitHub:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
.terraform/
```

## Limitacion Actual

El snippet cloud-init se referencia con:

```hcl
cicustom = "user=local:snippets/stattracker-cloud-init.yml"
```

Esto significa que el YAML debe existir en Proxmox en:

```text
/var/lib/vz/snippets/stattracker-cloud-init.yml
```

Terraform no renderiza automaticamente variables dentro de ese YAML. Si se cambian credenciales o ramas, hay que mantener sincronizados `terraform.tfvars`, `cloud-init` y/o Ansible.
