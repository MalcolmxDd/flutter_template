# 🔥 Configuración de Firebase para Flutter Template

Esta guía te ayudará a configurar Firebase en tu proyecto Flutter Template.

## 📋 Prerrequisitos

1. ✅ Proyecto de Firebase creado en [Firebase Console](https://console.firebase.google.com/)
2. ✅ Authentication habilitado (Email/Password)
3. ✅ Realtime Database creado
4. ✅ Flutter SDK instalado

## 🚀 Pasos de Configuración

### 1. Descargar Archivos de Configuración

#### Para Android:
1. Ve a Firebase Console → Configuración del proyecto
2. En la pestaña "General", busca tu app Android
3. Descarga el archivo `google-services.json`
4. Colócalo en: `android/app/google-services.json`

#### Para iOS (opcional):
1. Descarga el archivo `GoogleService-Info.plist`
2. Colócalo en: `ios/Runner/GoogleService-Info.plist`

#### Para Web (opcional):
1. Copia la configuración de Firebase
2. Crea el archivo: `web/firebase-config.js`

### 2. Configurar Android

#### En `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.flutter_template"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-database'
}
```

#### En `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### En `android/app/build.gradle` (al final):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Configurar iOS (opcional)

#### En `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4. Configurar Web (opcional)

#### Crear `web/firebase-config.js`:
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getDatabase } from 'firebase/database';

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  databaseURL: "https://YOUR_PROJECT-default-rtdb.firebaseio.com",
  projectId: "YOUR_PROJECT",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "123456789",
  appId: "YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const database = getDatabase(app);
```

#### En `web/index.html`:
```html
<script type="module" src="firebase-config.js"></script>
```

### 5. Configurar Realtime Database

#### Reglas de Seguridad (en Firebase Console):
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('roles').hasChild('admin')",
        ".write": "$uid === auth.uid || root.child('users').child(auth.uid).child('roles').hasChild('admin')"
      }
    },
    "scannedCodes": {
      "$codeId": {
        ".read": "data.child('userId').val() === auth.uid || root.child('users').child(auth.uid).child('roles').hasChild('admin')",
        ".write": "data.child('userId').val() === auth.uid || root.child('users').child(auth.uid).child('roles').hasChild('admin')"
      }
    },
    "settings": {
      ".read": "auth != null",
      ".write": "root.child('users').child(auth.uid).child('roles').hasChild('admin')"
    }
  }
}
```

### 6. Actualizar Configuración en el Código

#### En `lib/src/services/firebase_config.dart`:
Actualiza las URLs y configuraciones con los valores de tu proyecto:

```dart
static const String databaseUrl = 'https://YOUR_PROJECT-default-rtdb.firebaseio.com';
```

## 🧪 Probar la Configuración

1. Ejecuta `flutter pub get`
2. Ejecuta `flutter run`
3. Verifica que no hay errores de Firebase en la consola
4. Intenta registrar un usuario nuevo

## 🔧 Solución de Problemas

### Error: "No Firebase App '[DEFAULT]' has been created"
- Verifica que `google-services.json` esté en la ubicación correcta
- Ejecuta `flutter clean` y `flutter pub get`

### Error: "Firebase project not found"
- Verifica que el `projectId` en la configuración sea correcto
- Asegúrate de que el proyecto esté activo en Firebase Console

### Error de permisos en Realtime Database
- Verifica las reglas de seguridad
- Asegúrate de que el usuario esté autenticado

## 📚 Recursos Adicionales

- [Documentación oficial de Firebase Flutter](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Reglas de seguridad de Realtime Database](https://firebase.google.com/docs/database/security)

## 🎯 Próximos Pasos

1. ✅ Configurar archivos de Firebase
2. ✅ Probar autenticación
3. ✅ Probar Realtime Database
4. ✅ Migrar completamente de SQLite a Firebase
5. ✅ Remover dependencias de SQLite

---

**Nota**: Esta plantilla está diseñada para ser reutilizable. Simplemente reemplaza las configuraciones con las de tu proyecto y estará lista para usar.
