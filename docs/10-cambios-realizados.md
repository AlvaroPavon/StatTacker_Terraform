# Cambios Realizados

## Correcciones En La VM

Se corrigio la VM `Terraform-StatTracker`:

- Se configuro Apache con variables `DB_*`.
- Se verifico la base de datos `proyecto_imc`.
- Se comprobo que las tablas `usuarios` y `metricas` existen.
- Se genero `css/tailwind.css` local.
- Se copio `css/animate.min.css` local.
- Se reemplazaron referencias CDN en PHP.
- Se ajusto CSP para funcionar por HTTP en IP privada.
- Se habilitaron servicios al arranque:
  - `apache2`
  - `mariadb`
- Se activo arranque automatico de la VM en Proxmox.

## Cambios En Terraform

En `main.tf`:

- Se anadio `start_at_node_boot = true`.
- Se anadio `startup_shutdown` con orden de arranque.

Tambien se dejo `.terraform.lock.hcl` compatible con Linux despues de inicializar Terraform dentro de la VM.

## Cambios En Ansible

Se creo `ansible/`:

- Inventario para `192.168.5.34`.
- Configuracion con `become_method = su`.
- Playbook `site.yml`.
- Rol `stattracker`.
- Plantillas Apache y Tailwind.
- Tareas para instalar paquetes, clonar app, preparar DB, generar CSS, parchear CSP y verificar HTTP.

## Cambios En Documentacion

Se creo esta documentacion en `docs/` y se actualizo `README.md` como entrada principal del proyecto.

## Comprobaciones Ejecutadas

En la VM:

```bash
terraform validate
ansible-playbook site.yml --syntax-check
ansible stattracker -m ping -e ansible_password=<SSH_PASSWORD> -e ansible_become_password=<ROOT_PASSWORD>
curl -sS -o /tmp/check.html -w '%{http_code}\n' http://localhost/
```

Resultados:

```text
Terraform validate: OK
Ansible syntax-check: OK
Ansible ping: pong
HTTP local: 200
Base de datos no disponible: 0 apariciones
```
