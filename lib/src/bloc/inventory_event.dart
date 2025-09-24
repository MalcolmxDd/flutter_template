part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class LoadInventory extends InventoryEvent {}

class AddProduct extends InventoryEvent {
  final Product product;

  const AddProduct({required this.product});

  @override
  List<Object> get props => [product];
}

class UpdateProduct extends InventoryEvent {
  final String id;
  final Product product;

  const UpdateProduct({required this.id, required this.product});

  @override
  List<Object> get props => [id, product];
}

class DeleteProduct extends InventoryEvent {
  final String id;

  const DeleteProduct({required this.id});

  @override
  List<Object> get props => [id];
}