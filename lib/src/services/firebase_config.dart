import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración de Firebase para la aplicación
class FirebaseConfig {
  /// Inicializar Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('✅ Firebase inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar Firebase: $e');
      }
      rethrow;
    }
  }

  /// Configuración para desarrollo
  static const Map<String, dynamic> developmentConfig = {
    'apiKey': 'YOUR_DEV_API_KEY',
    'authDomain': 'your-dev-project.firebaseapp.com',
    'databaseURL': 'https://your-dev-project-default-rtdb.firebaseio.com',
    'projectId': 'your-dev-project',
    'storageBucket': 'your-dev-project.appspot.com',
    'messagingSenderId': '123456789',
    'appId': '1:123456789:android:abcdef123456',
  };

  /// Configuración para producción
  static const Map<String, dynamic> productionConfig = {
    'apiKey': 'YOUR_PROD_API_KEY',
    'authDomain': 'your-prod-project.firebaseapp.com',
    'databaseURL': 'https://your-prod-project-default-rtdb.firebaseio.com',
    'projectId': 'your-prod-project',
    'storageBucket': 'your-prod-project.appspot.com',
    'messagingSenderId': '987654321',
    'appId': '1:987654321:android:fedcba654321',
  };

  /// Obtener configuración según el entorno
  static Map<String, dynamic> getConfig() {
    if (kDebugMode) {
      return developmentConfig;
    } else {
      return productionConfig;
    }
  }

  /// URLs de la base de datos
  static const String databaseUrl =
      'https://your-project-default-rtdb.firebaseio.com';

  /// Reglas de seguridad básicas para Realtime Database
  static const String securityRules =
      '''
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
''';

  /// Configuración de autenticación
  static const Map<String, bool> authProviders = {
    'email': true,
    'google': false,
    'facebook': false,
    'twitter': false,
    'github': false,
  };

  /// Configuración de la base de datos
  static const Map<String, dynamic> databaseConfig = {
    'enablePersistence': true,
    'cacheSizeBytes': 10000000, // 10MB
    'enableNetwork': true,
  };
}
