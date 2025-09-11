import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc() : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<DeactivateUser>(_onDeactivateUser);
    on<LoadUserStats>(_onLoadUserStats);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      final users = await FirebaseDatabaseService.getAllUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onAddUser(AddUser event, Emitter<UsersState> emit) async {
    try {
      await FirebaseDatabaseService.createUserWithEmailAndPassword(
        email: event.userData['email'],
        password: event.userData['password'],
        username: event.userData['username'],
        role: event.userData['roles'] ?? 'user',
      );
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      final uid = event.userData['uid']?.toString() ?? '';
      final username = event.userData['username']?.toString();
      final email = event.userData['email']?.toString();
      final role = event.userData['roles']?.toString() ?? 'user';

      if (uid.isEmpty) {
        emit(const UsersError(error: 'UID de usuario requerido'));
        return;
      }

      await FirebaseDatabaseService.updateUserProfile(
        uid: uid,
        username: username,
        email: email,
        role: role,
      );

      if (event.userData.containsKey('isActive')) {
        await FirebaseDatabaseService.updateUserActiveStatus(
          uid,
          event.userData['isActive'] as bool,
        );
      }

      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    try {
      await FirebaseDatabaseService.deactivateUser(event.userId);
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onDeactivateUser(
    DeactivateUser event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await FirebaseDatabaseService.updateUserActiveStatus(event.userId, false);
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onLoadUserStats(
    LoadUserStats event,
    Emitter<UsersState> emit,
  ) async {
    try {
      final stats = await FirebaseDatabaseService.getUserStats();

      emit(
        UserStatsLoaded(
          totalUsers: stats['totalUsers'] ?? 0,
          adminUsers: stats['adminUsers'] ?? 0,
          regularUsers: stats['activeUsers'] ?? 0,
        ),
      );
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }
}
