# Ansible Para StatTracker

Este directorio contiene el playbook que configura StatTracker dentro de la VM Debian por SSH.

Terraform crea o modifica la VM en Proxmox. Ansible deja el sistema operativo y la aplicacion en el estado correcto: paquetes, Apache, MariaDB, Composer, CSS local, CSP y validacion HTTP.

## Uso Rapido

```bash
cd ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

La VM actual no tiene `sudo`, por eso `ansible.cfg` e `inventory.ini` usan `su` como metodo de escalado.

## Inventario Actual

```text
192.168.5.34
```

Si cambia la IP, actualizar `inventory.ini`.

## Comprobacion

```bash
ansible-playbook site.yml --syntax-check
ansible stattracker -m ping -e ansible_password=<SSH_PASSWORD> -e ansible_become_password=<ROOT_PASSWORD>
```

## Documentacion Completa

Ver:

- `../docs/05-ansible.md`
- `../docs/07-despliegue.md`
- `../docs/08-troubleshooting.md`
