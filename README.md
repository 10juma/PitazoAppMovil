# Pitazo — App Móvil

App móvil para la plataforma **Pitazo**, sistema de gestión deportiva para ligas de fútbol 7. Desarrollada en Flutter para iOS y Android.

---

## Roles y acceso

La app soporta múltiples roles con dashboards independientes:

| Rol | Acceso |
|---|---|
| **Admin** | Equipos, canchas, partidos, reservas, comunicados |
| **Staff** | Calendario, canchas, perfil |
| **Árbitro** | Partidos asignados, evaluaciones, perfil |
| **Manager** | Partidos, confirmaciones de jugadores, alineaciones |
| **Jugador** | Partidos, estadísticas, perfil |
| **Patrocinador** | Estadísticas de exposición, facturas |

Un mismo correo puede pertenecer a múltiples ligas. Al iniciar sesión, la app muestra un selector de liga antes de entrar.

---

## Stack

- **Flutter** 3.x / Dart 3.x
- **Provider** — estado global
- **go_router** — navegación declarativa
- **Dio** — HTTP client
- **flutter_secure_storage** — almacenamiento seguro de token
- **local_auth** — Face ID / huella dactilar
- **firebase_messaging** — notificaciones push
- **signalr_netcore** — actualizaciones en tiempo real (partidos en vivo)
- **cached_network_image** — imágenes con caché

---

## Estructura

```
lib/
├── core/
│   ├── auth/          # Biometría
│   ├── config/        # Variables de entorno (URL del API)
│   ├── network/       # Dio client, SignalR, manejo de errores
│   ├── router/        # app_router.dart — rutas y guards
│   ├── storage/       # SecureStorage wrapper
│   └── theme/         # Colores, tema, paletas por rol
├── features/          # Un directorio por rol (data / providers / screens)
├── models/            # DTOs compartidos
└── shared/
    └── widgets/       # Componentes reutilizables (PitazoButton, PitazoTextField…)
```

---

## Configuración

En `lib/core/config/env.dart` ajusta la URL base del API:

```dart
static const String apiBase = 'https://api.pitazo.com.mx';
```

---

## Comandos

```bash
# Dependencias
flutter pub get

# Análisis estático
flutter analyze lib/

# Build iOS (genera .ipa para distribución)
flutter build ipa --release

# Build Android (genera .aab para Play Store)
flutter build appbundle --release

# Iconos y splash (si se cambian assets)
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Autenticación y biometría

1. El usuario ingresa correo y contraseña.
2. Si pertenece a una sola liga, entra directamente.
3. Si pertenece a múltiples ligas, se muestra `SelectTenantScreen` para elegir.
4. Tras el primer login con contraseña, se ofrece activar Face ID / huella para la próxima vez.
5. El token JWT se almacena en `flutter_secure_storage`.

---

## Notificaciones push

Firebase Cloud Messaging (FCM) está configurado en `lib/core/notifications/push_notification_service.dart`. Los archivos `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) deben estar presentes para builds de producción.
