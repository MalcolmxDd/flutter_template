part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Product> products;

  const InventoryLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class InventoryError extends InventoryState {
  final String error;

  const InventoryError(this.error);

  @override
  List<Object> get props => [error];
}