import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/data/database_helper.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DatabaseHelper _databaseHelper;

  AuthBloc(this._databaseHelper) : super(AuthInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _databaseHelper.getUser(event.username, event.password);
        if (user != null) {
          emit(AuthSuccess(username: event.username, roles: [user['role']]));
        } else {
          emit(const AuthFailure(error: 'Credenciales inválidas'));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString()));
      }
    });

    on<RegisterButtonPressed>((event, emit) async {
      emit(AuthLoading());
      try {
        await _databaseHelper.saveUser({
          'username': event.username,
          'password': event.password,
          'role': 'user', // Assign default role on registration
        });
        // After registering, we can consider the user logged in or redirect to login
        emit(AuthSuccess(username: event.username, roles: ['user']));
      } catch (e) {
        // Check for unique constraint error
        if (e.toString().contains('UNIQUE constraint failed')) {
            emit(const AuthFailure(error: 'El nombre de usuario ya existe.'));
        } else {
            emit(AuthFailure(error: e.toString()));
        }
      }
    });

    on<LogoutButtonPressed>((event, emit) {
      emit(AuthInitial());
    });

    on<EnsureAdminExists>((event, emit) async {
      try {
        await _databaseHelper.createAdminUserIfNotExists();
        emit(AdminEnsured());
      } catch (e) {
        emit(AuthFailure(error: 'Error al crear usuario admin: $e'));
      }
    });
  }
}