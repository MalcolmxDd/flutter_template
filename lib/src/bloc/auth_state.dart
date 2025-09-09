part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String username;
  final String role;

  const AuthSuccess({required this.username, this.role = 'user'});

  @override
  List<Object> get props => [username, role];
  
  bool get isAdmin => role == 'admin';
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class AdminEnsured extends AuthState {}
