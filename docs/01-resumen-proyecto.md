# Resumen Del Proyecto

## Objetivo

El objetivo del proyecto es desplegar StatTracker en una maquina virtual Debian dentro de Proxmox y dejar la web disponible automaticamente cuando arranque el nodo Proxmox.

StatTracker es una aplicacion PHP que usa:

- Apache como servidor web.
- PHP 8.2 como runtime.
- MariaDB/MySQL como base de datos.
- Composer para dependencias PHP.
- Tailwind CSS y Animate.css generados localmente para evitar depender de CDN externos.

## Resultado Actual

El entorno actual queda asi:

- Proxmox crea y ejecuta la VM.
- La VM arranca automaticamente con el nodo Proxmox.
- Debian inicia `apache2` y `mariadb/mysql` automaticamente.
- Apache sirve la web desde `/var/www/stattracker`.
- La web actual esta accesible en `http://192.168.5.34/`.
- El repositorio de infraestructura esta copiado dentro de la VM en `/home/stattracker/StatTacker_Terraform`.
- Terraform y Ansible estan instalados tambien dentro de la VM.

## Responsabilidad De Cada Herramienta

| Herramienta | Responsabilidad |
| --- | --- |
| Terraform | Crear y configurar la VM en Proxmox. |
| cloud-init | Primera configuracion automatica de la VM al arrancar por primera vez. |
| Ansible | Reaplicar configuracion de forma idempotente por SSH. |
| Apache | Servir la aplicacion PHP. |
| MariaDB/MySQL | Guardar usuarios y metricas de StatTracker. |
| Composer | Instalar dependencias PHP. |
| Node/NPM | Generar CSS local con Tailwind y copiar Animate.css. |

## Repositorios Implicados

- Infraestructura: `https://github.com/AlvaroPavon/StatTacker_Terraform.git`
- Aplicacion PHP: `https://github.com/AlvaroPavon/StatTracker.git`

El repositorio de infraestructura no contiene el codigo completo de la aplicacion. Lo clona durante el aprovisionamiento.
