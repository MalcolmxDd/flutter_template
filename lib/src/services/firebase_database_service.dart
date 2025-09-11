import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para manejar operaciones con Firebase Realtime Database
class FirebaseDatabaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crear perfil de usuario
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String role = 'user',
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email,
        'username': username,
        'roles': role,
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'isActive': true,
      };

      await _database.child('users').child(uid).set(userData);
    } catch (e) {
      throw 'Error al crear perfil de usuario: $e';
    }
  }

  /// Obtener perfil de usuario
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _database.child('users').child(uid).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener perfil de usuario: $e';
    }
  }

  /// Crear usuario con Firebase Auth y perfil
  static Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String role = 'user',
  }) async {
    try {
      // Crear usuario con Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Crear perfil en la base de datos
        await createUserProfile(
          uid: credential.user!.uid,
          email: email,
          username: username,
          role: role,
        );
      }
    } catch (e) {
      throw 'Error al crear usuario: $e';
    }
  }

  /// Actualizar perfil de usuario
  static Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? email,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      if (role != null) updates['roles'] = role;

      updates['updatedAt'] = ServerValue.timestamp;

      await _database.child('users').child(uid).update(updates);
    } catch (e) {
      throw 'Error al actualizar perfil de usuario: $e';
    }
  }

  /// Actualizar último login
  static Future<void> updateUserLastLogin(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'lastLogin': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar último login: $e';
    }
  }

  /// Actualizar estado activo del usuario
  static Future<void> updateUserActiveStatus(String uid, bool isActive) async {
    try {
      await _database.child('users').child(uid).update({
        'isActive': isActive,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar estado del usuario: $e';
    }
  }

  /// Eliminar perfil de usuario (marcar como eliminado)
  static Future<void> deleteUserProfile(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al marcar usuario como eliminado: $e';
    }
  }

  /// Desactivar un usuario y marcarlo como eliminado
  static Future<void> deactivateUser(String uid) async {
    try {
      // 1. Marcar como eliminado en la base de datos
      await _markUserAsDeleted(uid);

      // 2. Eliminar datos relacionados (ej. códigos escaneados)
      await _deleteUserScannedCodes(uid);
    } catch (e) {
      throw 'Error al desactivar usuario: $e';
    }
  }

  /// Función auxiliar para marcar un usuario como eliminado en la DB
  static Future<void> _markUserAsDeleted(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al marcar usuario como eliminado: $e';
    }
  }

  

  /// Función auxiliar para eliminar códigos escaneados
  static Future<void> _deleteUserScannedCodes(String uid) async {
    try {
      final codesSnapshot = await _database
          .child('scannedCodes')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (codesSnapshot.exists) {
        final Map<dynamic, dynamic> codes =
            codesSnapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};

        for (final entry in codes.entries) {
          updates['scannedCodes/${entry.key}'] = null;
        }

        await _database.update(updates);
      }
    } catch (e) {
      print('Error al eliminar códigos escaneados: $e');
    }
  }

  /// Obtener todos los usuarios (solo para administradores)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> users =
            snapshot.value as Map<dynamic, dynamic>;
        return users.entries
            .map((entry) => Map<String, dynamic>.from(entry.value as Map))
            .where((user) => user['isDeleted'] != true)
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener usuarios: $e';
    }
  }

  /// Obtener estadísticas de usuarios
  static Future<Map<String, int>> getUserStats() async {
    try {
      final users = await getAllUsers();
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = now.subtract(const Duration(days: 30));

      int totalUsers = users.length;
      int activeUsers = users.where((user) => user['isActive'] == true).length;
      int adminUsers = users.where((user) => user['roles'] == 'admin').length;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;

      for (final user in users) {
        final createdAt = user['createdAt'];
        if (createdAt != null) {
          final createdDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
          if (createdDate.isAfter(oneWeekAgo)) {
            newUsersThisWeek++;
          }
          if (createdDate.isAfter(oneMonthAgo)) {
            newUsersThisMonth++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'adminUsers': adminUsers,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
      };
    } catch (e) {
      throw 'Error al obtener estadísticas: $e';
    }
  }

  /// Guardar código escaneado
  static Future<void> saveScannedCode({
    required String uid,
    required String code,
    required String type,
    String? content,
  }) async {
    try {
      final userProfile = await getUserProfile(uid);
      final username = userProfile?['username'] ?? 'Usuario desconocido';
      final email = userProfile?['email'] ?? '';

      final scannedCodeData = {
        'code': code,
        'type': type,
        'content': content ?? '',
        'userId': uid,
        'username': username,
        'userEmail': email,
        'scannedAt': ServerValue.timestamp,
        'isActive': true,
      };

      await _database.child('scannedCodes').push().set(scannedCodeData);
    } catch (e) {
      throw 'Error al guardar código escaneado: $e';
    }
  }

  /// Obtener historial de códigos escaneados por usuario
  static Future<List<Map<String, dynamic>>> getScannedCodesHistory(
    String uid,
  ) async {
    try {
      final snapshot = await _database
          .child('scannedCodes')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> codes =
            snapshot.value as Map<dynamic, dynamic>;
        return codes.entries
            .map(
              (entry) => {
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value as Map),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener historial de códigos: $e';
    }
  }

  /// Obtener todos los códigos escaneados (solo para administradores)
  static Future<List<Map<String, dynamic>>> getAllScannedCodes() async {
    try {
      final snapshot = await _database.child('scannedCodes').get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> codes =
            snapshot.value as Map<dynamic, dynamic>;

        final codesList = <Map<String, dynamic>>[];

        for (final entry in codes.entries) {
          final codeData = Map<String, dynamic>.from(entry.value as Map);
          final userId = codeData['userId'] as String?;

          Map<String, dynamic>? userInfo;
          if (userId != null) {
            try {
              userInfo = await getUserProfile(userId);
            } catch (e) {
              userInfo = null;
            }
          }

          codesList.add({'id': entry.key, ...codeData, 'userInfo': userInfo});
        }

        codesList.sort((a, b) {
          final aTime = a['scannedAt'] ?? 0;
          final bTime = b['scannedAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return codesList;
      }
      return [];
    } catch (e) {
      throw 'Error al obtener todos los códigos: $e';
    }
  }

  /// Eliminar código escaneado
  static Future<void> deleteScannedCode(String codeId) async {
    try {
      await _database.child('scannedCodes').child(codeId).remove();
    } catch (e) {
      throw 'Error al eliminar código: $e';
    }
  }

  /// Obtener configuración de la aplicación
  static Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final snapshot = await _database.child('settings').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener configuración: $e';
    }
  }

  /// Actualizar configuración de la aplicación
  static Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      await _database.child('settings').update(settings);
    } catch (e) {
      throw 'Error al actualizar configuración: $e';
    }
  }

  /// Escuchar cambios en tiempo real en el perfil del usuario
  static Stream<Map<String, dynamic>?> listenToUserProfile(String uid) {
    return _database.child('users').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Escuchar cambios en tiempo real en los códigos escaneados
  static Stream<List<Map<String, dynamic>>> listenToScannedCodes(String uid) {
    return _database
        .child('scannedCodes')
        .orderByChild('userId')
        .equalTo(uid)
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final Map<dynamic, dynamic> codes =
                event.snapshot.value as Map<dynamic, dynamic>;
            return codes.entries
                .map(
                  (entry) => {
                    'id': entry.key,
                    ...Map<String, dynamic>.from(entry.value as Map),
                  },
                )
                .toList();
          }
          return [];
        });
  }
}
