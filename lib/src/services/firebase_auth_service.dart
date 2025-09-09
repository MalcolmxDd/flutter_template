import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';

/// Servicio de autenticación con Firebase
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener el usuario actual
  static User? get currentUser => _auth.currentUser;

  /// Stream del estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Iniciar sesión con email y contraseña
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar último login en la base de datos
      if (result.user != null) {
        await FirebaseDatabaseService.updateUserLastLogin(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Registrar nuevo usuario
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? adminCode,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Actualizar el display name
        await result.user!.updateDisplayName(username);

        // Crear perfil de usuario en la base de datos
        await FirebaseDatabaseService.createUserProfile(
          uid: result.user!.uid,
          email: email,
          username: username,
          role: 'user', // Rol por defecto
        );
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  /// Enviar email de restablecimiento de contraseña
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Actualizar contraseña
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'No hay usuario autenticado';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Eliminar cuenta de usuario
  static Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Eliminar datos del usuario de la base de datos
        await FirebaseDatabaseService.deleteUserProfile(user.uid);

        // Eliminar la cuenta de autenticación
        await user.delete();
      } else {
        throw 'No hay usuario autenticado';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Obtener información del usuario desde la base de datos
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      return await FirebaseDatabaseService.getUserProfile(uid);
    } catch (e) {
      throw 'Error al obtener perfil de usuario: $e';
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
      await FirebaseDatabaseService.updateUserProfile(
        uid: uid,
        username: username,
        email: email,
        role: role,
      );
    } catch (e) {
      throw 'Error al actualizar perfil: $e';
    }
  }

  /// Manejar excepciones de Firebase Auth
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
