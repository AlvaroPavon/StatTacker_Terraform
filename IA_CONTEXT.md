# Contexto del Proyecto: StatTracker en Proxmox con Terraform

> Este documento contiene toda la informacion necesaria para que una IA pueda entender el proyecto y continuar trabajando en el. Carga este archivo al inicio de una nueva conversacion.

---

## Resumen del Proyecto

Se esta desplegando la aplicacion **StatTracker** (app PHP + MySQL para seguimiento de estadisticas de salud) en una **maquina virtual de Proxmox** usando **Terraform** con **cloud-init** para la automatizacion completa.

- **Repositorio de la app:** https://github.com/AlvaroPavon/StatTracker
- **Tecnologia:** PHP 8.2, MySQL/MariaDB, Apache2, Composer
- **Infraestructura:** Proxmox VE con provider `telmate/proxmox`
- **Localizacion de archivos:** `C:\Users\alvar\Desktop\terraform\stattracker-proxmox\`
- **OS del usuario:** Windows (PowerShell)

---

## Arquitectura del Despliegue

```
┌─────────────────────────────────────────────────────────────┐
│                    Tu PC Windows                             │
│  Terraform CLI → API de Proxmox (https://IP:8006/api2/json) │
└────────────────────────┬────────────────────────────────────┘
                         │ crea y configura
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  VM: stattracker (clonada de debian-12-template)       │  │
│  │                                                       │  │
│  │  Cloud-init:                                          │  │
│  │  1. Instala Apache2 + PHP 8.2 + MySQL + Git + Composer│  │
│  │  2. Configura MySQL (BD: proyecto_imc, user: stattracker)│
│  │  3. Clona https://github.com/AlvaroPavon/StatTracker   │  │
│  │  4. composer install                                   │  │
│  │  5. Importa database.sql                               │  │
│  │  6. Configura Apache VirtualHost                       │  │
│  │                                                       │  │
│  │  Resultado: App accesible en http://<IP_VM>            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  Template: debian-12-template (VM 9000, cloud-init image)  │
│  Snippet: /var/lib/vz/snippets/stattracker-cloud-init.yml  │
└─────────────────────────────────────────────────────────────┘
```

---

## Estructura de Archivos del Proyecto

```
stattracker-proxmox/
├── providers.tf                          # Provider Proxmox + version de Terraform
├── main.tf                               # Recurso proxmox_vm_qemu "stattracker"
├── variables.tf                          # 18 variables definidas
├── outputs.tf                            # 6 outputs (IP, SSH, URL, DB, etc.)
├── terraform.tfvars                      # Valores reales (NO subir a Git)
├── terraform.tfvars.example              # Ejemplo/template de variables
├── .gitignore                            # Excluye .tfvars, .terraform/, .tfstate
├── README.md                             # Documentacion rapida del proyecto
├── GUIA_COMPLETA.md                      # Guia paso a paso detallada
├── IA_CONTEXT.md                         # ESTE archivo (contexto para IA)
├── setup-proxmox-template.ps1            # Script para crear template en Proxmox
└── proxmox-snippets/
    └── stattracker-cloud-init.yml        # Script cloud-config para la VM
```

---

## Contenido de Cada Archivo

### providers.tf

- Provider: `telmate/proxmox` version `3.0.2-rc07`
- Terraform required: `>= 1.0.0`
- Autenticacion: API Token (no usuario/password)
- `pm_tls_insecure = true` (certificados self-signed)

### main.tf

- Recurso: `proxmox_vm_qemu.stattracker`
- Clone from: `var.pm_template`
- OS type: `cloud-init`
- CPU: `var.vm_cores` cores, 1 socket, type `host`
- RAM: `var.vm_memory` MB
- Disco: `var.vm_disk_size` en `var.pm_storage`
- Red: `virtio` en `var.pm_bridge`, DHCP
- Cloud-init: usuario `var.ci_user`, password `var.ci_password`
- Snippet custom: `user=local:snippets/stattracker-cloud-init.yml`
- `lifecycle { ignore_changes = [sshkeys, cicustom] }`

### variables.tf (18 variables)

| Variable | Tipo | Default | Descripcion |
|----------|------|---------|-------------|
| `pm_api_url` | string | - | URL API Proxmox |
| `pm_api_token_id` | string | - | Token ID |
| `pm_api_token_secret` | string (sensitive) | - | Token Secret |
| `pm_node` | string | - | Nodo Proxmox |
| `pm_template` | string | - | Nombre del template cloud-init |
| `pm_pool` | string | `""` | Pool de recursos |
| `pm_storage` | string | `"local-lvm"` | Storage para discos |
| `pm_bridge` | string | `"vmbr0"` | Bridge de red |
| `vm_name` | string | `"stattracker"` | Nombre de la VM |
| `vm_cores` | number | `2` | CPUs |
| `vm_memory` | number | `2048` | RAM en MB |
| `vm_disk_size` | string | `"20G"` | Tamaño disco |
| `ci_user` | string | `"stattracker"` | Usuario VM |
| `ci_password` | string (sensitive) | - | Password VM |
| `ssh_key_file` | string | `""` | Ruta clave publica SSH |
| `github_repo` | string | URL del repo | Repo GitHub |
| `github_branch` | string | `"main"` | Rama a desplegar |
| `db_name` | string | `"proyecto_imc"` | Nombre BD |
| `db_user` | string | `"stattracker"` | Usuario MySQL |
| `db_password` | string (sensitive) | `"Stattracker2025!"` | Password MySQL |
| `db_root_password` | string (sensitive) | `"MySQLRoot2025!"` | Password root MySQL |

### outputs.tf (6 outputs)

- `vm_ip_address` → IP de la VM
- `vm_name` → Nombre
- `vm_id` → ID en Proxmox
- `ssh_command` → Comando SSH completo
- `app_url` → URL de la app
- `db_connection` → Datos de conexion DB (sensitive)

### proxmox-snippets/stattracker-cloud-init.yml

Formato cloud-config. Secciones:

1. **package_upgrade: true** - Actualiza al inicio
2. **packages:** apache2, php8.2 + extensiones, mysql-server, git, composer, unzip
3. **runcmd:**
   - `systemctl enable/start mysql`
   - `mysql -e "CREATE DATABASE proyecto_imc"`
   - `mysql -e "CREATE USER 'stattracker'@'localhost' IDENTIFIED BY '...'"`
   - `mysql -e "GRANT ALL ON proyecto_imc.* TO 'stattracker'@'localhost'"`
   - `git clone --branch main https://github.com/AlvaroPavon/StatTracker.git /var/www/stattracker`
   - `cd /var/www/stattracker && composer install --no-dev --optimize-autoloader`
   - `mysql proyecto_imc < /var/www/stattracker/database.sql`
   - Crear VirtualHost Apache en `/etc/apache2/sites-available/stattracker.conf`
   - `a2dissite 000-default`, `a2ensite stattracker`, `a2enmod rewrite`
   - `chown -R www-data:www-data /var/www/stattracker`
   - `systemctl enable/restart apache2`

---

## Estado Actual del Proyecto

### Lo que ESTA implementado

- [x] Archivos Terraform completos (providers, main, variables, outputs)
- [x] Snippet de cloud-init con instalacion completa
- [x] Documentacion (README, GUIA_COMPLETA)
- [x] .gitignore para proteger secrets
- [x] Ejemplo de terraform.tfvars

### Lo que el usuario NECESITA hacer manualmente

1. Crear API Token en Proxmox
2. Crear template cloud-init en Proxmox (Debian 12)
3. Subir snippet a `/var/lib/vz/snippets/` en Proxmox
4. Configurar `terraform.tfvars` con sus valores reales
5. Ejecutar `terraform init && terraform apply`

---

## Stack Tecnologico de StatTracker

Informacion sobre la aplicacion que se despliega:

- **Lenguaje:** PHP 8.0+
- **Framework:** MVC propio (sin framework externo)
- **Base de datos:** MySQL/MariaDB (BD: `proyecto_imc`)
- **Dependencias:** Composer (ver `composer.json` en el repo)
- **Servidor web:** Apache con `.htaccess`
- **Frontend:** HTML, CSS, JavaScript
- **Features:** Auth con Argon2id, WAF, 2FA TOTP, API REST con JWT, Rate Limiting
- **Schema:** `database.sql` en la raiz del repo
- **Ramas:** `main` (produccion)

---

## Comandos que el usuario ejecuta (Windows/PowerShell)

```powershell
# Directorio del proyecto
cd C:\Users\alvar\Desktop\terraform\stattracker-proxmox

# Si terraform no esta en PATH, usar ruta completa:
$tf = "C:\Users\alvar\Desktop\terraform\terraform_1.15.0_windows_386\terraform.exe"

# Inicializar
& $tf init

# Planificar
& $tf plan

# Aplicar
& $tf apply

# Outputs
& $tf output

# Destruir
& $tf destroy
```

---

## Proxmox: Datos Importantes

### Como crear un API Token

1. Web de Proxmox → Datacenter → Permissions → API Tokens → Add
2. User: `root@pam`, Token ID: `terraform`
3. Desmarcar "Privilege Separation"
4. Copiar el Secret (solo se muestra una vez)
5. Token ID completo: `root@pam!terraform`

### Como crear el template cloud-init

```bash
# En shell de Proxmox:
qm create 9000 --name debian-12-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm importdisk 9000 /ruta/debian-12-genericcloud-amd64.qcow2 local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide0 local-lvm:cloudinit
qm set 9000 --boot order=scsi0 --serial0 socket --vga serial0
qm template 9000
```

### Donde van los snippets

```
/var/lib/vz/snippets/stattracker-cloud-init.yml
```

### Verificar template

```bash
qm list  # Debe mostrar debian-12-template como template
pvesm status  # Ver storages disponibles
```

---

## Problemas Comunes y Soluciones

| Problema | Causa probable | Solucion |
|----------|----------------|----------|
| `401 Unauthorized` | Token incorrecto | Verificar pm_api_token_id y secret |
| `template not found` | Nombre no coincide | `qm list` para ver nombre exacto |
| `storage not found` | Storage no existe | `pvesm status` para ver disponibles |
| VM creada pero app no carga | Cloud-init no termino | Esperar 5-10 min, verificar `cloud-init status` |
| `composer install` falla | Sin internet en VM | Verificar red/DHCP en Proxmox |
| Apache no arranca | Puerto 80 ocupado | `sudo systemctl status apache2` |
| MySQL no arranca | Config incorrecta | `sudo systemctl status mysql` |

---

## Posibles Mejoras Futuras

Cosas que se podrian añadir al proyecto:

1. **IP estatica configurable** en vez de DHCP
2. **Certificado SSL** con Let's Encrypt en el cloud-init
3. **Firewall** en la VM (ufw)
4. **Backup automatico** de la base de datos
5. **Monitorizacion** con health check endpoint
6. **Docker** como alternativa al despliegue bare-metal
7. **Ansible** como provisioner en vez de cloud-init
8. **Multiple VMs** (separar app y DB)
9. **Load balancer** para alta disponibilidad
10. **CI/CD** para actualizar la app automaticamente

---

## Referencias

- **Terraform Proxmox Provider:** https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
- **Cloud-init docs:** https://cloudinit.readthedocs.io/
- **Proxmox API:** https://pve.proxmox.com/pve-docs/api-viewer/
- **StatTracker repo:** https://github.com/AlvaroPavon/StatTracker

---

## Instrucciones para la IA que lea este documento

Si estas leyendo esto en una nueva conversacion, el usuario necesita ayuda con su despliegue de StatTracker en Proxmox. Aqui tienes el contexto completo:

1. Los archivos Terraform ya estan creados en `C:\Users\alvar\Desktop\terraform\stattracker-proxmox\`
2. El usuario trabaja en **Windows** con **PowerShell**
3. Tiene **Terraform 1.15.0** descargado en `terraform_1.15.0_windows_386/`
4. La app es **PHP + MySQL** que se despliega con **cloud-init**
5. El snippet de cloud-init va en `/var/lib/vz/snippets/` en Proxmox

**Si el usuario pide modificar algo:**
- Los archivos a modificar estan en `C:\Users\alvar\Desktop\terraform\stattracker-proxmox\`
- Usa los paths absolutos de Windows con `C:\Users\alvar\Desktop\terraform\stattracker-proxmox\`
- Los comandos de Terraform se ejecutan desde ese directorio

**Si el usuario tiene errores:**
- Revisar la seccion de Troubleshooting en GUIA_COMPLETA.md
- Los errores mas comunes son de conectividad a Proxmox, template no encontrado, o cloud-init que no termina

**Si el usuario quiere añadir funcionalidad:**
- Para cambiar la instalacion de la VM → editar `proxmox-snippets/stattracker-cloud-init.yml`
- Para cambiar recursos de la VM → editar `variables.tf` o `terraform.tfvars`
- Para añadir mas recursos Terraform → editar `main.tf`
- Para cambiar outputs → editar `outputs.tf`
