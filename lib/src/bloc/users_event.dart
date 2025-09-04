part of 'users_bloc.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class LoadUsers extends UsersEvent {}

class AddUser extends UsersEvent {
  final Map<String, dynamic> userData;

  const AddUser(this.userData);

  @override
  List<Object> get props => [userData];
}

class UpdateUser extends UsersEvent {
  final Map<String, dynamic> userData;

  const UpdateUser(this.userData);

  @override
  List<Object> get props => [userData];
}

class DeleteUser extends UsersEvent {
  final int userId;

  const DeleteUser(this.userId);

  @override
  List<Object> get props => [userId];
}

class DeactivateUser extends UsersEvent {
  final int userId;

  const DeactivateUser(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadUserStats extends UsersEvent {}
