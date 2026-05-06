# Ansible para StatTracker

Este playbook configura StatTracker dentro de la VM Debian por SSH. Complementa a Terraform: Terraform crea la VM en Proxmox y Ansible deja instalado Apache, PHP, MariaDB, Composer, la app y los CSS locales.

## Requisitos

Instala Ansible en el nodo de control. En Linux o WSL:

```bash
sudo apt update
sudo apt install -y ansible
```

La VM actual no tiene `sudo`, por eso el inventario usa `su` como metodo de escalado. Cuando Ansible pida la contraseña SSH y la contraseña de `su`, usa la contraseña correspondiente del usuario `stattracker` y de root.

## Uso con la VM actual

```bash
cd ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

El inventario apunta ahora a `192.168.5.34`. Si Terraform crea otra IP, cambia `ansible_host` en `inventory.ini` o genera un inventario nuevo con `terraform output vm_ip_address`.

## Variables utiles

Las variables principales estan en `roles/stattracker/defaults/main.yml`. Puedes sobrescribirlas con `--extra-vars` o variables de entorno:

```bash
STATTRACKER_DB_PASSWORD='otra-password' ansible-playbook site.yml --ask-pass --ask-become-pass
```

## Que configura

- Paquetes Debian necesarios para Apache, PHP, MariaDB, Composer, Node/NPM y curl.
- Base de datos `proyecto_imc` y usuario MySQL `stattracker`.
- Repositorio `AlvaroPavon/StatTracker` en `/var/www/stattracker`.
- Dependencias Composer.
- CSS local `css/tailwind.css` y `css/animate.min.css`, sin depender del CDN.
- VirtualHost Apache con variables `DB_*`.
- CSP compatible con acceso HTTP por IP privada de LAN.
- Verificacion HTTP final contra `http://localhost/`.
