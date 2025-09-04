import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/data/database_helper.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final DatabaseHelper _databaseHelper;

  UsersBloc(this._databaseHelper) : super(UsersInitial()) {
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
      final users = await _databaseHelper.getAllUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onAddUser(AddUser event, Emitter<UsersState> emit) async {
    try {
      await _databaseHelper.saveUser(event.userData);
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      await _databaseHelper.updateUser(event.userData);
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    try {
      await _databaseHelper.deleteUser(event.userId);
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
      await _databaseHelper.deactivateUser(event.userId);
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
      final totalUsers = await _databaseHelper.getUsersCount();
      final adminUsers = await _databaseHelper.getUsersCountByRole('admin');
      final regularUsers = await _databaseHelper.getUsersCountByRole('user');

      emit(
        UserStatsLoaded(
          totalUsers: totalUsers,
          adminUsers: adminUsers,
          regularUsers: regularUsers,
        ),
      );
    } catch (e) {
      emit(UsersError(error: e.toString()));
    }
  }
}
