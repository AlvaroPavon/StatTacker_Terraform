# Guia Completa: Despliegue de StatTracker en Proxmox con Terraform

## Indice

1. [Que vamos a hacer](#1-que-vamos-a-hacer)
2. [Requisitos previos](#2-requisitos-previos)
3. [Paso 1: Crear API Token en Proxmox](#3-paso-1-crear-api-token-en-proxmox)
4. [Paso 2: Crear Template Cloud-Init en Proxmox](#4-paso-2-crear-template-cloud-init-en-proxmox)
5. [Paso 3: Subir el Snippet de Cloud-Init](#5-paso-3-subir-el-snippet-de-cloud-init)
6. [Paso 4: Configurar Terraform en tu PC](#6-paso-4-configurar-terraform-en-tu-pc)
7. [Paso 5: Desplegar la VM](#7-paso-5-desplegar-la-vm)
8. [Paso 6: Verificar el despliegue](#8-paso-6-verificar-el-despliegue)
9. [Explicacion de cada archivo](#9-explicacion-de-cada-archivo)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Que vamos a hacer

Vamos a desplegar la aplicacion **StatTracker** (PHP + MySQL) en una maquina virtual de **Proxmox** usando **Terraform**. El proceso automatizado hace lo siguiente:

- Crea una VM en Proxmox desde un template cloud-init
- Instala automaticamente: Apache, PHP 8.2, MySQL, Git, Composer
- Clona tu repositorio de GitHub
- Configura la base de datos y importa el esquema
- Configura Apache para servir la aplicacion

Al final tendras tu aplicacion accesible desde el navegador en la IP de la VM.

---

## 2. Requisitos previos

### Lo que necesitas tener

| Requisito | Descripcion |
|-----------|-------------|
| Proxmox VE | Instalado y funcionando en tu red |
| Acceso root a Proxmox | Para crear templates y API tokens |
| Terraform | Instalado en tu PC Windows (ya tienes el zip en la carpeta) |
| Conexión a internet | La VM necesitara descargar paquetes y clonar el repo |
| Espacio en disco | Al menos 20GB libres en tu storage de Proxmox |

### Verificar que Terraform funciona

```powershell
# Si ya tienes terraform extraido en terraform_1.15.0_windows_386:
cd C:\Users\alvar\Desktop\terraform\terraform_1.15.0_windows_386
.\terraform.exe version

# Si quieres añadirlo al PATH para usarlo desde cualquier sitio:
# 1. Mueve terraform.exe a C:\Windows\System32\
# 2. O añade la carpeta al PATH de Windows
```

---

## 3. Paso 1: Crear API Token en Proxmox

### Por que necesitamos un API Token

Terraform necesita comunicarse con Proxmox para crear maquinas virtuales. En lugar de usar usuario/contraseña (menos seguro), usamos un **API Token** que es una credencial especifica con permisos controlados.

### Pasos

1. **Abre la web de Proxmox** en tu navegador:
   ```
   https://<IP_DE_TU_PROXMOX>:8006
   ```

2. **Inicia sesion** con tu usuario root (o usuario con permisos de administrador)

3. **Ve a Datacenter** (en el arbol de la izquierda, el icono de la casa)

4. **Navega a Permissions > API Tokens**

5. **Haz click en "Add"**

6. **Rellena el formulario:**
   - **User:** Selecciona `root@pam` (o tu usuario de Proxmox)
   - **Token ID:** Escribe `terraform`
   - **Privilege Separation:** **DESMARCA** esta casilla (importante, si no tendras que asignar permisos manualmente)
   - **Expire:** Puedes dejarlo sin fecha de expiracion o poner una futura

7. **Haz click en "Add"**

8. **¡IMPORTANTE!** Se mostrara una ventana con el **API Token Secret**. Copialo y guardalo en un lugar seguro. **Solo se muestra una vez**. El formato sera algo como:
   ```
   a1b2c3d4-e5f6-7890-abcd-ef1234567890
   ```

9. **Toma nota de estos dos valores** (los necesitaras para Terraform):
   - **Token ID completo:** `root@pam!terraform`
   - **Token Secret:** `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

---

## 4. Paso 2: Crear Template Cloud-Init en Proxmox

### Que es un Template Cloud-Init

Un template cloud-init es una imagen de sistema operativo preconfigurada que permite la inicializacion automatica de maquinas virtuales. Terraform clona este template y le inyecta configuracion (usuario, red, scripts) en el primer arranque.

### Opcion A: Crear template desde la web de Proxmox (recomendado)

1. **Descargar la imagen cloud-init de Debian 12:**
   ```
   https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
   ```
   Puedes descargarla desde tu navegador o desde la shell de Proxmox:
   ```bash
   wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
   ```

2. **Subir la imagen a Proxmox:**
   - En la web de Proxmox, selecciona tu nodo (ej: `pve`)
   - Ve a `local` > `ISO Images` > `Upload`
   - Sube el archivo `.qcow2` descargado

   O por consola SSH a Proxmox:
   ```bash
   # Copiar desde tu PC a Proxmox
   scp debian-12-genericcloud-amd64.qcow2 root@TU_IP_PROXMOX:/var/lib/vz/template/iso/
   ```

3. **Crear la VM template:**
   - En la web de Proxmox, haz click en **"Create VM"** (esquina superior derecha)
   - Rellena:
     - **General:**
       - VM ID: `9000`
       - Name: `debian-12-template`
     - **OS:**
       - Selecciona "Use existing CD/DVD disk image file"
       - Selecciona "Do not use any media" (cloud-init no necesita ISO)
       - Guest OS: Type = `Linux`, Version = `6.x - 2.6 Kernel`
     - **System:**
       - Graphic card: `Default`
       - SCSI Controller: `VirtIO SCSI single`
       - Qemu Agent: **ACTIVADO**
     - **Disks:**
       - Bus/Device: `SCSI`
       - Disk size: `4G` (es solo el template, luego la VM tendra su propio disco)
       - Storage: `local-lvm`
     - **CPU:**
       - Sockets: `1`
       - Cores: `2`
       - Type: `host`
     - **Memory:**
       - `2048` MB
     - **Network:**
       - Model: `VirtIO (paravirtualized)`
       - Bridge: `vmbr0`

4. **Importar el disco cloud-init:**
   Abre la **Shell** de Proxmox y ejecuta:
   ```bash
   qm importdisk 9000 /ruta/donde/esta/debian-12-genericcloud-amd64.qcow2 local-lvm
   ```

5. **Adjuntar el disco importado:**
   - En la web de Proxmox, ve a la VM `9000` > `Hardware`
   - Selecciona el `Unused Disk 0` que aparece
   - Haz click en **"Edit"** y añadelo como `SCSI`

6. **Crear disco Cloud-Init:**
   - En `Hardware` de la VM `9000`
   - Haz click en **"Add"** > **"Cloud-Init Drive"**
   - Storage: `local-lvm`

7. **Configurar arranque y consola:**
   En la Shell de Proxmox:
   ```bash
   qm set 9000 --boot order=scsi0
   qm set 9000 --serial0 socket
   qm set 9000 --vga serial0
   ```

8. **Convertir en template:**
   - Haz click derecho sobre la VM `9000`
   - Selecciona **"Convert to template"**

### Opcion B: Crear template por consola (rapido)

Conecta por SSH a tu Proxmox y ejecuta:

```bash
# Descargar imagen
wget -O /tmp/debian-12-cloud.qcow2 \
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

# Crear VM
qm create 9000 --name debian-12-template \
  --memory 2048 --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci

# Importar disco
qm importdisk 9000 /tmp/debian-12-cloud.qcow2 local-lvm

# Adjuntar disco
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0

# Crear cloud-init drive
qm set 9000 --ide0 local-lvm:cloudinit

# Configurar boot y consola serial
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket
qm set 9000 --vga serial0

# Convertir en template
qm template 9000

# Limpiar
rm /tmp/debian-12-cloud.qcow2
```

### Verificar que el template existe

```bash
qm list
# Deberias ver debian-12-template con estado template
```

---

## 5. Paso 3: Subir el Snippet de Cloud-Init

### Que es el Snippet

El snippet de cloud-init (`stattracker-cloud-init.yml`) es un script que se ejecuta dentro de la VM durante el primer arranque. Se encarga de instalar todo el software necesario y configurar la aplicacion.

### Subir el snippet a Proxmox

#### Opcion A: Desde tu PC Windows con SCP

Abre PowerShell y ejecuta:

```powershell
# Cambia TU_IP_PROXMOX por la IP real de tu Proxmox
scp "C:\Users\alvar\Desktop\terraform\stattracker-proxmox\proxmox-snippets\stattracker-cloud-init.yml" root@TU_IP_PROXMOX:/var/lib/vz/snippets/
```

#### Opcion B: Crear el archivo directamente en Proxmox por SSH

```bash
ssh root@TU_IP_PROXMOX

# Crear directorio si no existe
mkdir -p /var/lib/vz/snippets

# Crear el archivo con el editor nano
nano /var/lib/vz/snippets/stattracker-cloud-init.yml
```

Pega el contenido del archivo `stattracker-cloud-init.yml` y guarda con `Ctrl+X`, `Y`, `Enter`.

#### Opcion C: Copiar y pegar desde la consola de Proxmox

Si no tienes SCP disponible, puedes crear el archivo manualmente en Proxmox con el contenido que esta en `proxmox-snippets/stattracker-cloud-init.yml`.

### Verificar que el snippet se subio correctamente

```bash
ssh root@TU_IP_PROXMOX
ls -la /var/lib/vz/snippets/
# Deberias ver stattracker-cloud-init.yml
```

### Que hace el snippet

El archivo `stattracker-cloud-init.yml` ejecuta estos pasos en orden:

1. **Actualiza paquetes** del sistema (`apt update && apt upgrade`)
2. **Instala software:**
   - Apache2 (servidor web)
   - PHP 8.2 + extensiones (mysql, mbstring, xml, curl, zip, gd, intl, opcache)
   - libapache2-mod-php8.2 (modulo PHP para Apache)
   - MySQL Server (base de datos)
   - Git (para clonar el repo)
   - Composer (gestor de dependencias PHP)
   - unzip (necesario para Composer)
3. **Configura MySQL:**
   - Crea la base de datos `proyecto_imc`
   - Crea el usuario `stattracker` con contraseña
   - Otorga permisos
4. **Clona el repositorio** de GitHub en `/var/www/stattracker`
5. **Instala dependencias PHP** con `composer install`
6. **Importa el esquema** de la base de datos desde `database.sql`
7. **Configura Apache:**
   - Crea un VirtualHost para StatTracker
   - Deshabilita el sitio por defecto
   - Habilita mod_rewrite (necesario para .htaccess)
   - Reinicia Apache
8. **Configura permisos** correctos para www-data

---

## 6. Paso 4: Configurar Terraform en tu PC

### 6.1 Configurar el archivo de variables

```powershell
# Ir al directorio del proyecto
cd C:\Users\alvar\Desktop\terraform\stattracker-proxmox

# Copiar el ejemplo de variables
cp terraform.tfvars.example terraform.tfvars
```

### 6.2 Editar terraform.tfvars

Abre el archivo con tu editor favorito:

```powershell
notepad terraform.tfvars
```

Debes rellenar **al menos** estos campos:

```hcl
# --- PROXMOX (obligatorio) ---
pm_api_url          = "https://192.168.1.100:8006/api2/json"   # Cambia por tu IP
pm_api_token_id     = "root@pam!terraform"                       # Tu Token ID completo
pm_api_token_secret = "a1b2c3d4-e5f6-..."                        # Tu Token Secret

# --- TEMPLATE (obligatorio) ---
pm_template = "debian-12-template"   # Debe coincidir con el nombre de tu template

# --- PASSWORDS (obligatorio) ---
ci_password      = "TuPasswordVM123!"        # Password del usuario de la VM
db_password      = "StattrackerDB2025!"      # Password de MySQL para stattracker
db_root_password = "MySQLRoot2025!"          # Password root de MySQL
```

**Los demas campos pueden dejar sus valores por defecto:**

| Variable | Valor por defecto | Para que sirve |
|----------|-------------------|----------------|
| `pm_node` | `pve` | Nombre del nodo Proxmox |
| `pm_pool` | `""` (vacio) | Pool de recursos |
| `pm_storage` | `local-lvm` | Donde se guardan los discos |
| `pm_bridge` | `vmbr0` | Bridge de red |
| `vm_name` | `stattracker` | Nombre de la VM |
| `vm_cores` | `2` | CPUs |
| `vm_memory` | `2048` | RAM en MB |
| `vm_disk_size` | `20G` | Tamaño del disco |
| `ci_user` | `stattracker` | Usuario de la VM |
| `ssh_key_file` | `""` (vacio) | Clave publica SSH (opcional) |
| `github_repo` | URL de tu repo | Repositorio a clonar |
| `github_branch` | `main` | Rama a desplegar |
| `db_name` | `proyecto_imc` | Nombre de la BD |
| `db_user` | `stattracker` | Usuario de MySQL |

### 6.3 Si usas clave SSH (opcional)

Si quieres poder conectar por SSH con clave en vez de contraseña:

```hcl
ssh_key_file = "C:\\Users\\alvar\\.ssh\\id_rsa.pub"
```

Asegurate de que la ruta usa dobles barras invertidas `\\` en Windows.

---

## 7. Paso 5: Desplegar la VM

### 7.1 Inicializar Terraform

```powershell
cd C:\Users\alvar\Desktop\terraform\stattracker-proxmox

# Si terraform no esta en el PATH, usa la ruta completa:
C:\Users\alvar\Desktop\terraform\terraform_1.15.0_windows_386\terraform.exe init
```

Esto descargara el provider de Proxmox. Deberias ver algo como:
```
Terraform has been successfully initialized!
```

### 7.2 Planificar (ver que se va a crear)

```powershell
terraform.exe plan
```

Esto te muestra un resumen de lo que Terraform va a hacer. Deberia decir algo como:
```
Plan: 1 to add, 0 to change, 0 to destroy.
```

Si ves errores, revisa:
- Que `terraform.tfvars` tiene los valores correctos
- Que el API Token es valido
- Que el template existe en Proxmox

### 7.3 Aplicar (crear la VM)

```powershell
terraform.exe apply
```

Te pedira confirmacion. Escribe `yes` y pulsa Enter.

### 7.4 Esperar a que termine

El despliegue tarda entre **5 y 15 minutos** dependiendo de tu conexion y hardware. Terraform:
1. Crea la VM en Proxmox
2. La arranca
3. Cloud-init instala todo el software
4. Clona el repositorio y configura la app

**No interrumpas el proceso.** Si se corta, puedes reanudar con otro `terraform apply`.

### 7.5 Ver resultados

Cuando termine, veras los outputs:

```
Outputs:

app_url = "http://192.168.1.200"
ssh_command = "ssh stattracker@192.168.1.200"
vm_ip_address = "192.168.1.200"
vm_id = 100
vm_name = "stattracker"
```

### 7.6 Ver los outputs en cualquier momento

```powershell
terraform.exe output
terraform.exe output vm_ip_address
terraform.exe output app_url
```

---

## 8. Paso 6: Verificar el despliegue

### 8.1 Acceder a la aplicacion

Abre tu navegador y ve a la IP que te mostro Terraform:

```
http://<IP_DE_LA_VM>
```

Deberias ver la pagina de login de StatTracker.

### 8.2 Conectar por SSH

```powershell
# Con contraseña:
ssh stattracker@<IP_DE_LA_VM>
# (usa la contraseña que pusiste en ci_password)

# O con el comando que te da Terraform:
terraform.exe output ssh_command
```

### 8.3 Verificar servicios en la VM

```bash
# Estado de Apache
sudo systemctl status apache2

# Estado de MySQL
sudo systemctl status mysql

# Ver que la app esta sirviendo
curl -I http://localhost
# Deberia devolver HTTP/1.1 200 OK
```

### 8.4 Verificar base de datos

```bash
# Conectar a MySQL
mysql -u stattracker -p proyecto_imc

# Ver tablas
SHOW TABLES;

# Salir
EXIT;
```

### 8.5 Ver logs de cloud-init (si algo fallo)

```bash
# Log principal
sudo cat /var/log/cloud-init.log

# Output de los comandos
sudo cat /var/log/cloud-init-output.log

# Logs de Apache
sudo tail -50 /var/log/apache2/stattracker-error.log
```

---

## 9. Explicacion de cada archivo

### providers.tf

Define que proveedor usa Terraform y como conectarse a Proxmox.

```hcl
terraform {
  required_version = ">= 1.0.0"         # Version minima de Terraform
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"       # Provider oficial de la comunidad
      version = "3.0.2-rc07"           # Version especifica
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url          # URL de la API de Proxmox
  pm_api_token_id     = var.pm_api_token_id     # Token ID
  pm_api_token_secret = var.pm_api_token_secret # Token Secret
  pm_tls_insecure     = true                     # Aceptar certificados self-signed
}
```

### main.tf

Define la maquina virtual que se va a crear.

```hcl
resource "proxmox_vm_qemu" "stattracker" {
  # --- Identificacion ---
  name        = var.vm_name          # Nombre de la VM
  target_node = var.pm_node          # Nodo Proxmox donde crearla

  # --- Hardware ---
  agent  = 1                         # QEMU Guest Agent (comunicacion host-guest)
  memory = var.vm_memory             # RAM
  cpu {
    cores   = var.vm_cores           # Nucleos
    sockets = 1
    type    = "host"                 # Usa el mismo tipo de CPU que el host
  }

  # --- Sistema ---
  os_type = "cloud-init"             # Tipo de OS para cloud-init
  clone   = var.pm_template          # Template del que clonar
  boot    = "order=scsi0"            # Orden de arranque

  # --- Cloud-Init ---
  ciuser     = var.ci_user           # Usuario a crear
  cipassword = var.ci_password       # Su contraseña
  ipconfig0  = "ip=dhcp"             # Configuracion de red (DHCP)
  skip_ipv6  = true                  # Sin IPv6
  ciupgrade  = true                  # apt update && apt upgrade al arrancar

  # --- Snippet cloud-init personalizado ---
  cicustom = "user=local:snippets/stattracker-cloud-init.yml"

  # --- Discos ---
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.pm_storage   # Donde guardar el disco
          size    = var.vm_disk_size # Tamaño
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.pm_storage   # Disco cloud-init
        }
      }
    }
  }

  # --- Red ---
  network {
    id    = 0
    model = "virtio"                 # Driver paravirtualizado (mejor rendimiento)
    bridge = var.pm_bridge           # Bridge de red
  }

  # --- Consola serial (necesaria para cloud-init) ---
  serial { id = 0 }

  # --- Ignorar cambios en estos campos (evita recrear la VM) ---
  lifecycle {
    ignore_changes = [sshkeys, cicustom]
  }
}
```

### variables.tf

Define todas las variables que se pueden configurar en `terraform.tfvars`. Cada variable tiene:
- `description`: Para que sirve
- `type`: Tipo de dato
- `default`: Valor por defecto (opcional)
- `sensitive`: Si es true, no se muestra en los outputs

### outputs.tf

Define que informacion mostrar despues del despliegue:

```hcl
output "vm_ip_address" { ... }   # IP de la VM
output "vm_name" { ... }          # Nombre
output "vm_id" { ... }            # ID en Proxmox
output "ssh_command" { ... }      # Comando SSH listo para copiar
output "app_url" { ... }          # URL de la aplicacion
output "db_connection" { ... }    # Datos de conexion a MySQL (sensible)
```

### terraform.tfvars

Archivo con tus valores reales. **Nunca subir a Git.** Terraform lo lee automaticamente.

### .gitignore

Evita que se suban a Git archivos con informacion sensible:
- `*.tfvars` → Contiene passwords
- `.terraform/` → Plugins descargados
- `terraform.tfstate` → Estado de la infraestructura (contiene secrets)

### proxmox-snippets/stattracker-cloud-init.yml

Script que se ejecuta dentro de la VM. Formato `cloud-config`:

```yaml
#cloud-config
package_upgrade: true        # Actualizar paquetes al inicio

packages:                    # Lista de paquetes a instalar
  - apache2
  - php
  - mysql-server
  - git
  - composer
  ...

runcmd:                      # Comandos a ejecutar (en orden)
  - systemctl enable mysql   # Habilitar MySQL
  - mysql -e "CREATE DATABASE ..."  # Crear BD
  - git clone ...            # Clonar repo
  - composer install         # Instalar dependencias
  - mysql proyecto_imc < database.sql  # Importar esquema
  - cat > /etc/apache2/...   # Configurar Apache
  - systemctl restart apache2
```

---

## 10. Troubleshooting

### Error: "connection refused" o "timeout" al hacer terraform init/plan/apply

**Causa:** La URL de Proxmox es incorrecta o no hay conexion de red.

**Solucion:**
```powershell
# Verificar que puedes acceder a Proxmox
curl -k https://TU_IP_PROXMOX:8006/api2/json

# Deberia devolver algo de JSON. Si no, revisa:
# - La IP es correcta
# - El puerto 8006 esta abierto
# - No hay firewall bloqueando
```

### Error: "401 Unauthorized" o "invalid token"

**Causa:** El API Token es incorrecto o no tiene permisos.

**Solucion:**
1. Verifica que `pm_api_token_id` tiene el formato `usuario@realm!token_id`
2. Verifica que `pm_api_token_secret` es correcto
3. En Proxmox, ve a `Permissions` y comprueba que el token existe
4. Si marcaste "Privilege Separation" al crear el token, desmarcalo y crea uno nuevo

### Error: "cloud-init template not found"

**Causa:** El nombre del template no coincide.

**Solucion:**
```bash
# En Proxmox, listar templates
qm list

# El nombre en pm_template debe coincidir exactamente
# con el campo "Name" de la lista
```

### Error: "storage not found" o "pool not found"

**Causa:** El storage o pool no existen en tu Proxmox.

**Solucion:**
```bash
# Ver storages disponibles
pvesm status

# Ver pools disponibles
pvesh get /pools
```

Ajusta `pm_storage` y `pm_pool` en `terraform.tfvars`.

### La VM se crea pero la app no carga

**Posible causa 1: Cloud-init no termino**

```bash
# Espera unos minutos mas. Cloud-init puede tardar 5-10 min
# Verificar estado en la VM:
ssh stattracker@<IP>
sudo cloud-init status
# Si dice "running", espera. Si dice "done", continua.
```

**Posible causa 2: Apache no arranco**

```bash
ssh stattracker@<IP>
sudo systemctl status apache2
sudo journalctl -u apache2 --no-pager -n 50
```

**Posible causa 3: Composer fallo**

```bash
ssh stattracker@<IP>
cd /var/www/stattracker
sudo composer install
# Mira si hay errores de dependencias
```

**Posible causa 4: MySQL no arranco**

```bash
ssh stattracker@<IP>
sudo systemctl status mysql
sudo mysql -e "SELECT 1"
# Si pide password y no funciona:
sudo mysql -u root -e "SELECT 1"
```

**Posible causa 5: El repo no se clono**

```bash
ssh stattracker@<IP>
ls -la /var/www/stattracker
# Si esta vacio o no existe:
cd /var/www
sudo git clone https://github.com/AlvaroPavon/StatTracker.git
```

### Error: "ssh key file not found"

**Causa:** La ruta a la clave SSH no existe o esta mal escrita.

**Solucion:**
```powershell
# Verificar que el archivo existe
Test-Path "C:\Users\alvar\.ssh\id_rsa.pub"

# Si no existe, genera una clave:
ssh-keygen -t ed25519

# O deja ssh_key_file vacio en terraform.tfvars
ssh_key_file = ""
```

### Quiero cambiar algo y reaplicar

```powershell
# Editar terraform.tfvars con los nuevos valores
notepad terraform.tfvars

# Ver que cambiara
terraform.exe plan

# Aplicar cambios
terraform.exe apply
```

### Quiero destruir todo y empezar de nuevo

```powershell
# Destruir la VM
terraform.exe destroy

# Confirmar con "yes"

# Volver a crear
terraform.exe apply
```

### La VM tiene IP pero no puedo acceder por SSH

**Verificar:**
1. Que el puerto 22 esta abierto en la VM
2. Que el usuario y contraseña son correctos
3. Que no hay firewall bloqueando

```powershell
# Probar conexion al puerto 22
Test-NetConnection -ComputerName <IP_VM> -Port 22
```

### Quiero usar una IP estatica en vez de DHCP

Edita `main.tf` y cambia la linea:

```hcl
# Cambiar esto:
ipconfig0 = "ip=dhcp"

# Por esto (ajusta a tu red):
ipconfig0 = "ip=192.168.1.200/24,gw=192.168.1.1"
```

### Quiero mas o menos recursos

Edita `terraform.tfvars`:

```hcl
vm_cores     = 4        # Mas CPUs
vm_memory    = 4096     # Mas RAM (4GB)
vm_disk_size = "40G"    # Mas disco
```

Luego ejecuta `terraform apply`.

---

## Resumen rapido de comandos

```powershell
# 1. Ir al proyecto
cd C:\Users\alvar\Desktop\terraform\stattracker-proxmox

# 2. Inicializar (solo la primera vez)
terraform.exe init

# 3. Planificar
terraform.exe plan

# 4. Desplegar
terraform.exe apply

# 5. Ver outputs
terraform.exe output

# 6. Destruir
terraform.exe destroy
```
