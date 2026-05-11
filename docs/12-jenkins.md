# Jenkins

## Funcion

Jenkins queda instalado en la misma VM Debian que StatTracker para preparar trabajos de CI/CD del proyecto.

El despliegue se hace con Ansible, no manualmente, para que pueda repetirse despues de recrear la VM.

## Acceso

URL actual:

```text
http://192.168.5.34:8080/
```

Pantalla de login/configuracion:

```text
http://192.168.5.34:8080/login
```

## Primer Desbloqueo

En la primera instalacion Jenkins pide una contrasena inicial. No se guarda en Git ni en Markdown.

Para verla dentro de la VM:

```bash
su -
cat /var/lib/jenkins/secrets/initialAdminPassword
```

Despues se completa el asistente web:

1. Abrir `http://192.168.5.34:8080/`.
2. Pegar la contrasena inicial.
3. Instalar los plugins sugeridos o seleccionar plugins manualmente.
4. Crear el primer usuario administrador.

## Instalacion Gestionada Por Ansible

El rol `stattracker` instala Jenkins LTS con repositorios oficiales:

| Componente | Ruta / paquete |
| --- | --- |
| Repositorio Jenkins LTS | `/etc/apt/sources.list.d/jenkins.list` |
| Clave Jenkins 2026 | `/etc/apt/keyrings/jenkins-keyring.asc` |
| Repositorio Adoptium | `/etc/apt/sources.list.d/adoptium.list` |
| Clave Adoptium | `/etc/apt/keyrings/adoptium.gpg` |
| Java | `temurin-21-jdk` |
| Jenkins | `jenkins` |
| Puerto | `8080` |
| Override systemd | `/etc/systemd/system/jenkins.service.d/override.conf` |

Jenkins actual requiere Java 21 para las versiones recientes. En Debian 12 se instala Temurin 21 desde Adoptium.

## Servicio

Comprobar estado:

```bash
systemctl status jenkins
systemctl is-enabled jenkins
```

Arrancar, parar o reiniciar:

```bash
systemctl start jenkins
systemctl stop jenkins
systemctl restart jenkins
```

Ver logs:

```bash
journalctl -u jenkins -n 100 --no-pager
journalctl -u jenkins -f
```

Comprobar Java:

```bash
java -version
```

Resultado esperado: Java 21.

## Verificacion HTTP

Desde la VM:

```bash
curl -I http://localhost:8080/login
```

Resultado esperado:

```text
HTTP/1.1 200 OK
X-Jenkins: <version>
```

Desde otro equipo de la LAN:

```text
http://192.168.5.34:8080/login
```

## Cambiar El Puerto

El puerto esta definido en:

```text
ansible/roles/stattracker/defaults/main.yml
```

Variable:

```yaml
jenkins_port: 8080
```

Si se cambia, Ansible escribe el override de systemd y reinicia Jenkins.

## Copias De Seguridad

El estado principal de Jenkins esta en:

```text
/var/lib/jenkins
```

Antes de borrar o recrear Jenkins, guardar esa ruta si hay jobs, credenciales o configuracion que conservar.

## Referencias Oficiales

- Jenkins Linux install: `https://www.jenkins.io/doc/book/installing/linux/`
- Jenkins Debian LTS repo: `https://pkg.jenkins.io/debian-stable/`
- Adoptium Linux packages: `https://adoptium.net/installation/linux`
