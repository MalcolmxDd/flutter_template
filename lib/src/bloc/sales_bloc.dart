import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'sales_event.dart';
part 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  SalesBloc() : super(SalesInitial()) {
    on<SellProduct>(_onSellProduct);
  }

  Future<void> _onSellProduct(
    SellProduct event,
    Emitter<SalesState> emit,
  ) async {
    emit(SalesLoading());
    try {
      // Obtener el producto para calcular el total
      final products = await FirebaseDatabaseService.getProducts();
      final product = products.firstWhere((p) => p.id == event.productId);

      final total = product.price * event.quantity;
      final sale = Sale(
        userId: event.userId,
        productId: event.productId,
        quantity: event.quantity,
        total: total,
        date: DateTime.now(),
      );

      await FirebaseDatabaseService.registerSale(sale);
      emit(SalesSuccess(sale));
    } catch (e) {
      emit(SalesError(e.toString()));
      rethrow; // Re-throw para que el caller pueda manejar
    }
  }
}