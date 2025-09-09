import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await FirebaseAuthService.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        
        if (userCredential?.user != null) {
          final userProfile = await FirebaseAuthService.getUserProfile(userCredential!.user!.uid);
          final role = userProfile?['roles'] ?? 'user';
          final username = userProfile?['username'] ?? userCredential.user!.displayName ?? 'Usuario';
          
          emit(AuthSuccess(username: username, role: role));
        } else {
          emit(const AuthFailure(error: 'Error de autenticación'));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    on<RegisterButtonPressed>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await FirebaseAuthService.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
          username: event.username,
        );
        
        if (userCredential?.user != null) {
          emit(AuthSuccess(username: event.username, role: 'user'));
        } else {
          emit(const AuthFailure(error: 'Error al crear la cuenta'));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    on<LogoutButtonPressed>((event, emit) async {
      try {
        await FirebaseAuthService.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(error: 'Error al cerrar sesión: $e'));
      }
    });

    on<CheckAuthStatus>((event, emit) async {
      try {
        final user = FirebaseAuthService.currentUser;
        if (user != null) {
          final userProfile = await FirebaseAuthService.getUserProfile(user.uid);
          final role = userProfile?['roles'] ?? 'user';
          final username = userProfile?['username'] ?? user.displayName ?? 'Usuario';
          
          emit(AuthSuccess(username: username, role: role));
        } else {
          emit(AuthInitial());
        }
      } catch (e) {
        emit(AuthInitial());
      }
    });
  }
}