# Operacion Y Acceso

## Acceso Web

Entorno actual:

```text
http://192.168.5.34/
```

Si se recrea la VM y cambia la IP:

```bash
terraform output vm_ip_address
terraform output app_url
```

## Acceso SSH

Entorno actual:

```bash
ssh stattracker@192.168.5.34
```

La contrasena no se documenta en Git. Debe obtenerse de `terraform.tfvars` o del administrador del entorno.

## Escalado A Root

La VM actual usa `su -`, no `sudo`:

```bash
su -
```

## Rutas Importantes

| Ruta | Uso |
| --- | --- |
| `/var/www/stattracker` | Aplicacion PHP desplegada. |
| `/var/www/stattracker/css/tailwind.css` | CSS local generado. |
| `/var/www/stattracker/css/animate.min.css` | Animate.css local. |
| `/etc/apache2/sites-available/stattracker.conf` | VirtualHost Apache. |
| `/var/log/apache2/stattracker-error.log` | Log de errores Apache. |
| `/var/log/apache2/stattracker-access.log` | Log de accesos Apache. |
| `/home/stattracker/StatTacker_Terraform` | Repo de infraestructura dentro de la VM. |

## Servicios

Comprobar estado:

```bash
systemctl status apache2
systemctl status mysql
systemctl status mariadb
```

Comprobar arranque automatico:

```bash
systemctl is-enabled apache2
systemctl is-enabled mariadb
systemctl is-enabled mysql
```

En el estado actual:

```text
apache2: enabled / active
mariadb: enabled
mysql: alias / active
```

## Comprobacion Rapida De La Web

Dentro de la VM:

```bash
curl -sS -o /tmp/stattracker.html -w '%{http_code}\n' http://localhost/
grep -c 'Base de datos no disponible' /tmp/stattracker.html
grep -c 'css/tailwind.css' /tmp/stattracker.html
```

Resultado esperado:

```text
200
0
1
```

## Herramientas Instaladas En La VM

Se dejaron instaladas y probadas:

```text
Terraform v1.15.2
Ansible core 2.14.18
ansible-playbook core 2.14.18
sshpass 1.09
```

## Proyecto Dentro De La VM

Ruta:

```bash
cd /home/stattracker/StatTacker_Terraform
```

Comandos verificados:

```bash
terraform validate
cd ansible
ansible-playbook site.yml --syntax-check
```
