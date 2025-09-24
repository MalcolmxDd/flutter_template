part of 'sales_bloc.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object> get props => [];
}

class SellProduct extends SalesEvent {
  final String productId;
  final int quantity;
  final String userId;

  const SellProduct({
    required this.productId,
    required this.quantity,
    required this.userId,
  });

  @override
  List<Object> get props => [productId, quantity, userId];
}