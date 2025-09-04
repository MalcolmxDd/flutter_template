part of 'users_bloc.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<Map<String, dynamic>> users;

  const UsersLoaded({required this.users});

  @override
  List<Object> get props => [users];
}

class UserStatsLoaded extends UsersState {
  final int totalUsers;
  final int adminUsers;
  final int regularUsers;

  const UserStatsLoaded({
    required this.totalUsers,
    required this.adminUsers,
    required this.regularUsers,
  });

  @override
  List<Object> get props => [totalUsers, adminUsers, regularUsers];
}

class UsersError extends UsersState {
  final String error;

  const UsersError({required this.error});

  @override
  List<Object> get props => [error];
}
