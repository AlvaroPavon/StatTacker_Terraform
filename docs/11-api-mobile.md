# API Y Aplicacion Movil

## Estado

StatTracker incluye una API REST PHP dentro del repositorio principal de la aplicacion:

```text
/var/www/stattracker/api
```

La API usa la misma base de datos que la web:

```text
proyecto_imc
```

Endpoints principales:

| Metodo | Ruta | Uso |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Registrar usuario. |
| `POST` | `/api/auth/login` | Login y emision de JWT. |
| `POST` | `/api/auth/logout` | Logout cliente. |
| `GET` | `/api/metrics` | Listar metricas del usuario. |
| `POST` | `/api/metrics` | Crear metrica. |
| `GET` | `/api/metrics/:id` | Ver una metrica. |
| `PUT` | `/api/metrics/:id` | Actualizar una metrica. |
| `DELETE` | `/api/metrics/:id` | Eliminar una metrica. |
| `GET` | `/api/profile` | Ver perfil y estadisticas. |
| `PUT` | `/api/profile` | Actualizar perfil. |
| `POST` | `/api/profile/password` | Cambiar contrasena. |

## URLs En Proxmox

URL canonica:

```text
http://192.168.5.34/api
```

Documentacion Swagger incluida en la app:

```text
http://192.168.5.34/api/docs/
```

URL legacy mantenida para clientes antiguos que tenian `proyecto_imc` en la URL:

```text
http://192.168.5.34/proyecto_imc/api
```

El VirtualHost de Apache sirve la app desde `/var/www/stattracker` y define un `Alias /proyecto_imc` hacia el mismo directorio. Ademas, Ansible parchea `api/index.php` para que el router acepte las dos bases: `/api` y `/proyecto_imc/api`.

## Comprobacion Rapida

Desde la VM:

```bash
curl -i -X POST http://localhost/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{}'

curl -i -X POST http://localhost/proyecto_imc/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Resultado esperado: `400 Bad Request` por faltar email y contrasena. Si devuelve `404` con `Endpoint no encontrado`, el router de la API o el Alias de Apache no estan aplicados.

## Aplicacion Movil Android

La app Android esta en el repo de aplicacion:

```text
StatTrackerMobile/
```

La interfaz Retrofit define rutas como:

```kotlin
@POST("api/auth/login")
@GET("api/metrics")
@GET("api/profile")
```

Por eso la URL base de Android debe apuntar a la raiz web:

```text
http://192.168.5.34/
```

No debe apuntar a `http://192.168.5.34/api`, porque Retrofit acabaria construyendo rutas incorrectas.

La mejora aplicada en la app movil es usar `BuildConfig.STATTRACKER_BASE_URL` en lugar de una IP fija en `Constants.kt`. Valor por defecto:

```text
http://192.168.5.34/
```

Compilar contra otro entorno:

```bash
./gradlew :app:assembleDebug -PstattrackerBaseUrl=http://10.0.2.2:8000/
./gradlew :app:assembleDebug -PstattrackerBaseUrl=http://192.168.5.34/
```

## Seguridad

- La API usa JWT en `Authorization: Bearer <token>`.
- `api/config/cors.php` permite `Access-Control-Allow-Origin: *`; esto es util para LAN y pruebas moviles, pero debe restringirse si se publica fuera de la red privada.
- `api/config/jwt.php` contiene un secreto JWT fijo en codigo; para produccion debe moverse a variable de entorno o configuracion no versionada.
- Android tiene `usesCleartextTraffic=true` para permitir HTTP en LAN. Si se expone fuera del laboratorio, debe usarse HTTPS.
- El logging HTTP de la app movil debe estar activo solo en builds `debug`; en `release` no debe imprimir cuerpos, credenciales ni JWT.
- El despliegue en Proxmox relaja la deteccion de herramientas de `UltimateShield` solo para IPs privadas, para que los checks de salud con `curl` no bloqueen la IP de administracion.

## Mejoras Pendientes Recomendadas

1. Publicar HTTPS con certificado interno o reverse proxy.
2. Leer `JWT_SECRET` desde entorno Apache en vez de dejarlo fijo en el repo de aplicacion.
3. Restringir CORS a origenes controlados cuando deje de ser entorno LAN.
4. Versionar la API como `/api/v1` si se preve compatibilidad a largo plazo.
5. Revisar que `.gradle/`, `local.properties` y artefactos Android no queden versionados en el repo de aplicacion.
