# Cloud-init

## Funcion

`proxmox-snippets/stattracker-cloud-init.yml` es el script que se ejecuta en el primer arranque de la VM. Instala paquetes, prepara MySQL, clona la aplicacion y configura Apache.

## Ubicacion

En el repositorio:

```text
proxmox-snippets/stattracker-cloud-init.yml
```

En Proxmox:

```text
/var/lib/vz/snippets/stattracker-cloud-init.yml
```

## Que Instala

- `apache2`
- `php`, `php8.2`, `libapache2-mod-php8.2`
- extensiones PHP necesarias: MySQL, mbstring, XML, curl, zip, gd, intl, opcache
- `mysql-server` o MariaDB segun Debian
- `git`
- `composer`
- `nodejs`
- `npm`
- `unzip`

## Que Configura

1. Arranca y habilita MySQL/MariaDB.
2. Crea la base de datos `proyecto_imc`.
3. Crea el usuario MySQL de la aplicacion.
4. Clona `https://github.com/AlvaroPavon/StatTracker.git` en `/var/www/stattracker`.
5. Ejecuta `composer install`.
6. Importa `database.sql`.
7. Genera CSS local con Tailwind.
8. Copia Animate.css local.
9. Reemplaza referencias CDN por CSS local.
10. Crea el VirtualHost Apache.
11. Activa modulos Apache: `rewrite`, `headers`, `expires`, `env`.
12. Ajusta permisos.
13. Reinicia Apache.

## Reejecucion

Cloud-init se ejecuta en el primer arranque. Si el archivo cambia despues, la VM no lo reaplica automaticamente.

Para aplicar cambios de cloud-init hay dos opciones:

1. Recrear la VM:

```bash
terraform apply -replace=proxmox_vm_qemu.stattracker
```

2. Aplicar cambios con Ansible sobre la VM existente.

Para este proyecto se recomienda usar Ansible cuando la VM ya existe.

## Logs

Dentro de la VM:

```bash
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log
```

Si la VM no tiene `sudo`, entrar como root con:

```bash
su -
```
