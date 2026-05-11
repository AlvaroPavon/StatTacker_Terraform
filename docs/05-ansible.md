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
2. Instala paquetes necesarios para repositorios APT externos.
3. Configura repositorio Adoptium para Java 21.
4. Configura repositorio Jenkins LTS.
5. Instala paquetes Debian de StatTracker.
6. Instala Jenkins y Temurin Java 21.
7. Habilita Apache, MariaDB y Jenkins.
8. Crea base de datos y usuario MySQL.
9. Clona o actualiza el repo de la aplicacion.
10. Ejecuta Composer.
11. Importa el esquema si faltan tablas.
12. Genera CSS local con Tailwind.
13. Copia Animate.css local.
14. Reemplaza enlaces CDN por CSS local.
15. Parchea CSP para acceso HTTP en LAN.
16. Parchea el router de la API para `/api` y `/proyecto_imc/api`.
17. Ajusta UltimateShield para permitir checks de salud desde LAN privada.
18. Crea VirtualHost Apache con Alias legacy `/proyecto_imc`.
19. Habilita modulos Apache.
20. Limpia bloqueos temporales de IPs privadas en `blocked_ips.json`.
21. Ajusta permisos.
22. Valida Apache.
23. Comprueba HTTP `200`.
24. Comprueba que no aparece el aviso de base de datos.
25. Comprueba que la API responde en la ruta canonica y en la ruta legacy.
26. Comprueba que Jenkins responde en `localhost:8080/login`.

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

Jenkins usa estas variables principales:

```yaml
jenkins_port: 8080
jenkins_key_url: https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
jenkins_repo_url: https://pkg.jenkins.io/debian-stable
```
