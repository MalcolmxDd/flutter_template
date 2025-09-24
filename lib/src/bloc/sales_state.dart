part of 'sales_bloc.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesSuccess extends SalesState {
  final Sale sale;

  const SalesSuccess(this.sale);

  @override
  List<Object> get props => [sale];
}

class SalesError extends SalesState {
  final String error;

  const SalesError(this.error);

  @override
  List<Object> get props => [error];
}