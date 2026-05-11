# Troubleshooting

## La Web Carga Sin CSS

Comprobar que el HTML referencia CSS local:

```bash
curl -s http://localhost/ | grep 'css/tailwind.css'
```

Comprobar que Apache sirve el CSS:

```bash
curl -I http://localhost/css/tailwind.css
```

Debe devolver:

```text
HTTP/1.1 200 OK
Content-Type: text/css
```

Comprobar que no quedan referencias al CDN:

```bash
grep -RIn 'cdn.tailwindcss.com\|animate.css/4.1.1' /var/www/stattracker/*.php
```

Si aparecen, ejecutar Ansible:

```bash
cd /home/stattracker/StatTacker_Terraform/ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

## La Web Dice "Base De Datos No Disponible"

Comprobar Apache:

```bash
grep -n 'SetEnv DB' /etc/apache2/sites-available/stattracker.conf
```

Comprobar MySQL/MariaDB:

```bash
mysql -NBe "USE proyecto_imc; SHOW TABLES;"
```

Comprobar conexion como usuario de la app:

```bash
mysql -ustattracker -p -e "USE proyecto_imc; SHOW TABLES;"
```

Comprobar logs:

```bash
tail -n 80 /var/www/stattracker/logs/php_errors.log
tail -n 80 /var/log/apache2/stattracker-error.log
```

## CSP Bloquea Recursos En HTTP

Sintoma:

- El CSS existe.
- Apache lo sirve como `text/css`.
- Chrome sigue mostrando HTML crudo o scripts bloqueados.

Comprobar cabecera:

```bash
curl -I http://localhost/ | grep -i content-security-policy
```

No debe forzar:

```text
upgrade-insecure-requests
block-all-mixed-content
```

El rol Ansible parchea `src/SecurityHeaders.php` para LAN privada.

## Proxmox No Arranca La VM Automaticamente

Comprobar en Proxmox:

```text
onboot = 1
startup = order=1,up=60,down=30
```

En Terraform debe existir:

```hcl
start_at_node_boot = true
```

## La API Devuelve 404

Comprobar la ruta canonica:

```bash
curl -i -X POST http://localhost/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Comprobar la ruta legacy:

```bash
curl -i -X POST http://localhost/proyecto_imc/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Resultado esperado: `400 Bad Request`. Si devuelve `Endpoint no encontrado`, ejecutar Ansible para aplicar el Alias de Apache y el parche del router:

```bash
cd /home/stattracker/StatTacker_Terraform/ansible
ansible-playbook site.yml --ask-pass --ask-become-pass
```

## La Web Devuelve 403 Desde La LAN

Sintoma:

- `curl http://localhost/` dentro de la VM devuelve `200`.
- `http://192.168.5.34/` desde otro equipo devuelve `403 Forbidden`.

Causa observada:

- `UltimateShield` detecta ciertos User-Agent de herramientas como `curl` y bloquea temporalmente la IP.
- El bloqueo queda en `/var/www/stattracker/logs/blocked_ips.json`.

Comprobar:

```bash
cat /var/www/stattracker/logs/blocked_ips.json
tail -n 40 /var/www/stattracker/logs/security.log
```

El rol Ansible corrige el comportamiento en LAN privada y limpia bloqueos temporales de rangos `10.x.x.x`, `172.16-31.x.x` y `192.168.x.x`.

## Jenkins No Responde

Comprobar servicio:

```bash
systemctl status jenkins
journalctl -u jenkins -n 100 --no-pager
```

Comprobar Java:

```bash
java -version
```

Debe mostrar Java 21. Si Jenkins arranca pero no carga, comprobar:

```bash
curl -I http://localhost:8080/login
systemctl cat jenkins
```

Si el puerto 8080 estuviera ocupado, cambiar `jenkins_port` en Ansible y ejecutar el playbook.

## Apache O MariaDB No Arrancan Con Debian

```bash
systemctl enable apache2
systemctl enable mariadb
systemctl is-enabled apache2
systemctl is-enabled mariadb
```

## Terraform No Encuentra El Snippet

El archivo debe estar en Proxmox:

```text
/var/lib/vz/snippets/stattracker-cloud-init.yml
```

Y `main.tf` referencia:

```hcl
cicustom = "user=local:snippets/stattracker-cloud-init.yml"
```

## Ansible Ignora ansible.cfg

Si aparece:

```text
Ansible is being run in a world writable directory
```

Corregir permisos:

```bash
cd /home/stattracker/StatTacker_Terraform
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod 600 terraform.tfvars
```

## Terraform Provider Permission Denied

Si se corrigieron permisos y Terraform falla con `permission denied` en el provider:

```bash
cd /home/stattracker/StatTacker_Terraform
find .terraform/providers -type f -name 'terraform-provider-*' -exec chmod 755 {} \;
terraform validate
```
