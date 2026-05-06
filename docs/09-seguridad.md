# Seguridad Y Secretos

## No Subir Secretos

Nunca subir a GitHub:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
.terraform/
*.tfplan
ansible/.vault-pass
ansible/group_vars/*/vault.yml
```

## Secretos Del Proyecto

Los secretos reales son:

- Token API de Proxmox.
- Contrasena del usuario cloud-init.
- Contrasena del usuario SSH.
- Contrasena de root o `su -`.
- Contrasena MySQL/MariaDB.
- Cualquier clave privada SSH.

Estos valores deben estar solo en:

- `terraform.tfvars` local.
- gestor de secretos.
- entrega privada del administrador.

## Gitignore

`.gitignore` ignora estado local y secretos. `terraform.tfvars.example` si debe subirse porque es plantilla sin secretos reales.

## Recomendaciones

- Rotar el token de Proxmox si se ha compartido por error.
- Usar contrasenas distintas para SSH, root y base de datos.
- No documentar contrasenas en Markdown.
- No imprimir tokens en capturas.
- Revisar `git status` antes de hacer commit.
- Usar HTTPS real si la web se expone fuera de LAN.

## HTTPS

Ahora la web funciona por HTTP en LAN:

```text
http://192.168.5.34/
```

Si se publica fuera de la red local, configurar HTTPS con certificado valido y revisar CSP para poder reactivar:

```text
upgrade-insecure-requests
block-all-mixed-content
```
