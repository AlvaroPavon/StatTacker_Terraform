# StatTracker en Proxmox

Repositorio de infraestructura para desplegar y operar StatTracker en una VM de Proxmox usando Terraform, cloud-init y Ansible.

## Estado Actual

- VM en Proxmox: `Terraform-StatTracker`
- VMID actual: `1247`
- URL actual de la web: `http://192.168.5.34/`
- SSH actual: `ssh stattracker@192.168.5.34`
- Ruta del proyecto dentro de la VM: `/home/stattracker/StatTacker_Terraform`
- Aplicacion desplegada en la VM: `/var/www/stattracker`
- Servicios principales: `apache2` y `mariadb/mysql`
- Jenkins CI: `http://192.168.5.34:8080/`
- Arranque automatico en Proxmox: activado

No se documentan contrasenas ni tokens reales. Estan en `terraform.tfvars`, en Proxmox o en la entrega local del entorno.

## Documentacion

La documentacion completa esta en `docs/`:

- [Indice de documentacion](docs/INDICE.md)
- [Resumen del proyecto](docs/01-resumen-proyecto.md)
- [Arquitectura y componentes](docs/02-arquitectura.md)
- [Terraform](docs/03-terraform.md)
- [Cloud-init](docs/04-cloud-init.md)
- [Ansible](docs/05-ansible.md)
- [Operacion y acceso](docs/06-operacion-acceso.md)
- [Despliegue paso a paso](docs/07-despliegue.md)
- [Troubleshooting](docs/08-troubleshooting.md)
- [Seguridad y secretos](docs/09-seguridad.md)
- [Cambios realizados](docs/10-cambios-realizados.md)
- [API y aplicacion movil](docs/11-api-mobile.md)
- [Jenkins](docs/12-jenkins.md)
- [ENTREGABLE: Memoria completa del proyecto](docs/ENTREGABLE.md)

## Estructura Del Repositorio

```text
.
|-- main.tf
|-- providers.tf
|-- variables.tf
|-- outputs.tf
|-- terraform.tfvars.example
|-- proxmox-snippets/
|   `-- stattracker-cloud-init.yml
|-- ansible/
|   |-- ansible.cfg
|   |-- inventory.ini
|   |-- site.yml
|   `-- roles/stattracker/
|-- docs/
|-- setup-proxmox-template.ps1
`-- README.md
```

## Uso Rapido

Desde una maquina con Terraform:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Desde la VM actual:

```bash
cd /home/stattracker/StatTacker_Terraform
terraform validate

cd ansible
ansible-playbook site.yml --syntax-check
ansible stattracker -m ping -e ansible_password=<SSH_PASSWORD> -e ansible_become_password=<ROOT_PASSWORD>
```

Desde un navegador:

```text
http://192.168.5.34/
```

API para la app movil:

```text
http://192.168.5.34/api
```

Jenkins:

```text
http://192.168.5.34:8080/
```

## Regla Importante

No subir a GitHub:

- `terraform.tfvars`
- `terraform.tfstate`
- `.terraform/`
- contrasenas, tokens de Proxmox o claves privadas

Estos archivos quedan ignorados por `.gitignore`.
