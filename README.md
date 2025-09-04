# Flutter Template - Escáner de Códigos

## Descripción

Esta aplicación Flutter permite a los usuarios escanear códigos de barras y QR desde dispositivos móviles y sincronizarlos con computadoras. Es ideal para escenarios donde se necesita capturar códigos en el campo y tenerlos disponibles en el escritorio.

## Funcionalidades Principales

### 🔐 Sistema de Autenticación
- **Login/Registro**: Sistema completo de autenticación de usuarios
- **Gestión de Usuarios**: Panel de administración para gestionar usuarios y roles
- **Roles**: Sistema de permisos (admin/usuario)

### 📱 Escaneo de Códigos (Móvil)
- **Cámara en Tiempo Real**: Escaneo instantáneo de códigos QR y de barras
- **Tipos Soportados**: QR, Code 128, Code 39, EAN-13, EAN-8, UPC-A, UPC-E
- **Controles de Cámara**: Linterna, cambio de cámara, pausa/reanudación
- **Overlay Visual**: Guías de escaneo con marco decorativo
- **Confirmación**: Notificación inmediata de códigos escaneados

### 💻 Historial y Gestión (Computadora)
- **Vista Completa**: Lista de todos los códigos escaneados
- **Filtros Avanzados**: Por tipo de código y estado de sincronización
- **Búsqueda**: Encontrar códigos específicos rápidamente
- **Estado de Sincronización**: Visualizar qué códigos están sincronizados
- **Acciones**: Re-sincronización manual y eliminación de códigos

### 🔄 Sincronización Automática
- **Almacenamiento Local**: Base de datos SQLite para códigos escaneados
- **Sincronización Automática**: Los códigos se sincronizan automáticamente
- **Identificación de Dispositivos**: Cada código incluye información del dispositivo
- **Estado de Sincronización**: Seguimiento del estado de cada código

## Arquitectura Técnica

### Patrón BLoC
- **ScannerBloc**: Maneja eventos de escaneo y sincronización
- **AuthBloc**: Gestiona autenticación y autorización
- **UsersBloc**: Administra usuarios del sistema

### Base de Datos
- **SQLite**: Almacenamiento local de códigos y usuarios
- **Migraciones**: Sistema de versionado para actualizaciones de esquema
- **Tabla scanned_codes**: Almacena códigos con metadatos completos

### Dependencias Principales
- `mobile_scanner`: Escaneo de códigos QR/barras
- `flutter_bloc`: Manejo de estado de la aplicación
- `sqflite`: Base de datos local
- `http` & `web_socket_channel`: Preparado para sincronización con servidor

## Flujo de Uso

### 1. Escaneo en Móvil
1. Usuario abre la app en su dispositivo móvil
2. Navega a la sección "Escanear"
3. Apunta la cámara al código QR/barras
4. El código se escanea automáticamente
5. Se guarda localmente y se marca para sincronización

### 2. Visualización en Computadora
1. Usuario abre la app en su computadora
2. Navega a la sección "Historial"
3. Ve todos los códigos escaneados desde cualquier dispositivo
4. Puede filtrar, buscar y gestionar los códigos
5. Estado de sincronización visible para cada código

### 3. Sincronización
- Los códigos se sincronizan automáticamente cuando se escanean
- El estado de sincronización se actualiza en tiempo real
- Los usuarios pueden forzar re-sincronización manual si es necesario

## Instalación y Configuración

### Requisitos
- Flutter SDK 3.8.1+
- Dart 3.0+
- Dispositivo Android/iOS para escaneo
- Computadora para visualización y gestión

### Configuración
1. Clonar el repositorio
2. Ejecutar `flutter pub get`
3. Configurar permisos de cámara en dispositivos móviles
4. Ejecutar la aplicación

### Permisos de Cámara
- **Android**: Agregar `<uses-permission android:name="android.permission.CAMERA" />` en AndroidManifest.xml
- **iOS**: Agregar descripción de uso de cámara en Info.plist

## Estructura del Proyecto

```
lib/
├── src/
│   ├── bloc/
│   │   ├── scanner_bloc.dart      # Lógica del escáner
│   │   ├── auth_bloc.dart         # Autenticación
│   │   └── users_bloc.dart        # Gestión de usuarios
│   ├── data/
│   │   └── database_helper.dart   # Base de datos SQLite
│   └── presentation/
│       ├── pages/
│       │   ├── scanner_page.dart      # Página principal del escáner
│       │   ├── codes_history_page.dart # Historial de códigos
│       │   └── ...                    # Otras páginas
│       └── widgets/                    # Componentes reutilizables
```

## Próximos Pasos

### Sincronización con Servidor
- Implementar API REST para sincronización
- WebSockets para sincronización en tiempo real
- Autenticación JWT para comunicación segura

### Funcionalidades Adicionales
- Exportación de códigos a CSV/Excel
- Estadísticas de escaneo
- Notificaciones push para códigos importantes
- Integración con sistemas externos

### Mejoras de UX
- Modo oscuro para el escáner
- Personalización de guías de escaneo
- Sonidos de confirmación
- Vibración al escanear códigos

## Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Contacto

Para preguntas o soporte, contactar al equipo de desarrollo.
