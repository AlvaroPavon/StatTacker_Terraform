# StatTracker - Despliegue en Proxmox con Terraform

Despliega tu aplicacion StatTracker en una VM de Proxmox con un solo comando.

## Requisitos previos

1. **Proxmox VE** funcionando y accesible
2. **Template cloud-init** creado en Proxmox (Debian 12 recomendado)
3. **API Token** de Proxmox con permisos suficientes
4. **Terraform** instalado en tu maquina

## Estructura

```
stattracker-proxmox/
├── providers.tf                          # Provider de Proxmox
├── main.tf                               # Configuracion de la VM
├── variables.tf                          # Variables de entrada
├── outputs.tf                            # Salidas despues del despliegue
├── terraform.tfvars.example              # Ejemplo de variables (copiar a terraform.tfvars)
├── .gitignore                            # Ignora secrets y estado
└── proxmox-snippets/
    └── stattracker-cloud-init.yml        # Script cloud-init (subir a Proxmox)
```

## Paso 1: Preparar Proxmox

### 1.1 Crear un API Token

En la web de Proxmox:
1. Ve a `Datacenter` > `Permissions` > `API Tokens`
2. Click en `Add`
3. User: `root@pam` (o tu usuario)
4. Token ID: `terraform`
5. Desmarca `Privilege Separation`
6. Copia el **Secret** (solo se muestra una vez)

### 1.2 Crear un Template Cloud-Init (si no tienes uno)

```bash
# Descargar imagen cloud-init de Debian 12
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# Crear la VM
qm create 9000 --memory 2048 --cores 2 --name debian-12-template

# Importar el disco
qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm

# Adjuntar el disco
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Crear disco cloud-init
qm set 9000 --ide0 local-lvm:cloudinit

# Configurar red y boot
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket
qm set 9000 --vga serial0

# Convertir en template
qm template 9000
```

### 1.3 Subir el snippet de cloud-init

Copia el archivo `proxmox-snippets/stattracker-cloud-init.yml` a tu Proxmox:

```bash
# Desde tu maquina, copia el archivo a Proxmox
scp proxmox-snippets/stattracker-cloud-init.yml root@TU_PROXMOX_IP:/var/lib/vz/snippets/

# O por SSH directo en Proxmox:
# (crear el archivo en /var/lib/vz/snippets/stattracker-cloud-init.yml)
```

## Paso 2: Configurar Terraform

```bash
# Copiar el ejemplo de variables
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
# (usa notepad, vscode, o tu editor favorito)
notepad terraform.tfvars
```

Rellena al menos estos valores en `terraform.tfvars`:
- `pm_api_url` - URL de tu Proxmox
- `pm_api_token_id` - Tu API Token ID
- `pm_api_token_secret` - Tu API Token Secret
- `pm_template` - Nombre de tu template cloud-init
- `ci_password` - Password para el usuario de la VM
- `db_password` - Password para MySQL
- `db_root_password` - Password root de MySQL

## Paso 3: Desplegar

```bash
# Inicializar Terraform
terraform init

# Ver que se va a crear
terraform plan

# Desplegar
terraform apply
```

Tras unos minutos, Terraform te mostrara la IP y URL de tu aplicacion.

## Paso 4: Acceder a StatTracker

```bash
# Ver la IP de la VM
terraform output vm_ip_address

# Acceder desde el navegador
# http://<IP_DE_LA_VM>

# Conectar por SSH
terraform output ssh_command
```

## Personalizacion

### Cambiar recursos de la VM

Edita en `terraform.tfvars`:
```hcl
vm_cores     = 4
vm_memory    = 4096
vm_disk_size = "40G"
```

### Usar otra rama de GitHub

```hcl
github_branch = "develop"
```

### IP estatica en vez de DHCP

Edita `main.tf` y cambia:
```hcl
ipconfig0 = "ip=192.168.1.200/24,gw=192.168.1.1"
```

## Comandos utiles

```bash
# Ver estado actual
terraform show

# Ver outputs
terraform output

# Destruir la VM
terraform destroy

# Forzar re-creacion (si el cloud-init no se aplico)
terraform apply -replace=proxmox_vm_qemu.stattracker
```

## Troubleshooting

### Error: "cloud-init snippet not found"
Asegurate de que el archivo esta en `/var/lib/vz/snippets/stattracker-cloud-init.yml` en Proxmox.

### Error: "clone can't find template"
Verifica que el nombre en `pm_template` coincide exactamente con el nombre de tu template en Proxmox.

### La VM no responde
```bash
# Ver logs de cloud-init en la VM
ssh stattracker@<IP>
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

### La app no carga
```bash
# En la VM, verificar servicios
sudo systemctl status apache2
sudo systemctl status mysql

# Ver logs de Apache
sudo tail -f /var/log/apache2/stattracker-error.log
```

### La app carga sin estilos o dice "Base de datos no disponible"

Estos sintomas suelen indicar que la VM se creo con un snippet antiguo:

- La app usa Tailwind; el despliegue debe generar `css/tailwind.css` localmente para no depender de `cdn.tailwindcss.com`.
- La app PHP lee la conexion MySQL desde variables `DB_*`; Apache debe definir `DB_HOST`, `DB_DATABASE`, `DB_USERNAME` y `DB_PASSWORD`.

Despues de actualizar `proxmox-snippets/stattracker-cloud-init.yml`, vuelve a subirlo al host Proxmox y recrea la VM:

```bash
scp proxmox-snippets/stattracker-cloud-init.yml root@TU_PROXMOX_IP:/var/lib/vz/snippets/stattracker-cloud-init.yml
terraform apply -replace=proxmox_vm_qemu.stattracker
```

Cloud-init solo se ejecuta en el primer arranque. Si no recreas la VM, los cambios del snippet no se aplicaran automaticamente.

## Seguridad

- **Nunca** subas `terraform.tfvars` a Git (contiene passwords)
- Rota tu API Token de Proxmox periodicamente
- Usa contraseñas fuertes para MySQL y el usuario de la VM
- Considera configurar HTTPS con Let's Encrypt en la VM
