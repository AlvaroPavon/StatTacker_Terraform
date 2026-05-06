# Ansible

## Funcion

Ansible permite aplicar y reparar la configuracion de StatTracker por SSH sin recrear la VM. Es idempotente: se puede ejecutar varias veces y busca dejar el mismo estado final.

## Estructura

```text
ansible/
|-- ansible.cfg
|-- inventory.ini
|-- site.yml
`-- roles/
    `-- stattracker/
        |-- defaults/main.yml
        |-- handlers/main.yml
        |-- tasks/main.yml
        `-- templates/
```

## Inventario Actual

`ansible/inventory.ini` apunta a la VM actual:

```ini
[stattracker]
stattracker-vm ansible_host=192.168.5.34 ansible_user=stattracker ansible_become=true ansible_become_method=su ansible_become_user=root
```

La VM actual no tiene `sudo`, por eso se usa:

```text
become_method = su
```

## Que Hace El Rol

El rol `stattracker`:

1. Actualiza cache APT.
2. Instala paquetes Debian.
3. Habilita Apache y MariaDB.
4. Crea base de datos y usuario MySQL.
5. Clona o actualiza el repo de la aplicacion.
6. Ejecuta Composer.
7. Importa el esquema si faltan tablas.
8. Genera CSS local con Tailwind.
9. Copia Animate.css local.
10. Reemplaza enlaces CDN por CSS local.
11. Parchea CSP para acceso HTTP en LAN.
12. Parchea el router de la API para `/api` y `/proyecto_imc/api`.
13. Ajusta UltimateShield para permitir checks de salud desde LAN privada.
14. Crea VirtualHost Apache con Alias legacy `/proyecto_imc`.
15. Habilita modulos Apache.
16. Limpia bloqueos temporales de IPs privadas en `blocked_ips.json`.
17. Ajusta permisos.
18. Valida Apache.
19. Comprueba HTTP `200`.
20. Comprueba que no aparece el aviso de base de datos.
21. Comprueba que la API responde en la ruta canonica y en la ruta legacy.

## Comandos

Desde el repo:

```bash
cd ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

Desde la VM actual se comprobo:

```bash
cd /home/stattracker/StatTacker_Terraform/ansible
ansible-playbook site.yml --syntax-check
ansible stattracker -m ping -e ansible_password=<SSH_PASSWORD> -e ansible_become_password=<ROOT_PASSWORD>
```

Resultado esperado:

```text
stattracker-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Variables

Variables principales en:

```text
ansible/roles/stattracker/defaults/main.yml
```

La contrasena MySQL puede sobreescribirse con una variable de entorno:

```bash
STATTRACKER_DB_PASSWORD='valor' ansible-playbook site.yml --ask-pass --ask-become-pass
```

No guardar contrasenas reales en Markdown ni en Git.
