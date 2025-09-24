import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';
import 'package:flutter_template/src/bloc/sales_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final SalesBloc salesBloc;

  ScannerBloc({required this.salesBloc}) : super(ScannerInitial()) {
    on<ScanCode>(_onScanCode);
    on<SaveScannedCode>(_onSaveScannedCode);
    on<LoadScannedCodes>(_onLoadScannedCodes);
    on<DeleteScannedCode>(_onDeleteScannedCode);
    on<CreateProductFromScan>(_onCreateProductFromScan);
  }

  Future<void> _onScanCode(ScanCode event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const ScannerError(error: 'Usuario no autenticado'));
        return;
      }

      // Si se debe verificar código existente
      Map<String, dynamic>? existingCode;
      if (event.checkExisting) {
        try {
          existingCode = await FirebaseDatabaseService.findExistingCode(event.code);
        } catch (e) {
          // Si hay error al buscar, continuar sin datos existentes
          existingCode = null;
        }
      }

      // Si existe un código previo, emitir estado especial
      if (existingCode != null) {
        emit(CodeAlreadyExists(existingCode));
        return;
      }

      // Buscar producto por barcode
      Product? product;
      try {
        product = await FirebaseDatabaseService.findProductByBarcode(event.code);
      } catch (e) {
        // Si hay error al buscar producto, continuar sin producto
        product = null;
      }

      // Si se encontró producto y tiene stock > 0, intentar vender
      if (product != null && product.stock > 0) {
        try {
          // Vender producto usando SalesBloc
          salesBloc.add(SellProduct(
            productId: product.id!,
            quantity: 1,
            userId: user.uid,
          ));

          // Esperar el resultado de la venta
          final completer = Completer<void>();
          late StreamSubscription subscription;

          subscription = salesBloc.stream.listen((state) {
            if (state is SalesSuccess) {
              emit(SaleSuccess(state.sale));
              subscription.cancel();
              completer.complete();
            } else if (state is SalesError) {
              emit(SaleError(state.error));
              subscription.cancel();
              completer.complete();
            }
          });

          await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
            subscription.cancel();
            emit(SaleError('Timeout al procesar venta'));
          });

          return;
        } catch (e) {
          emit(SaleError('Error al procesar venta: $e'));
          return;
        }
      }

      // Si no se vendió producto, verificar si el usuario es admin para ofrecer crear producto
      final userProfile = await FirebaseDatabaseService.getUserProfile(user.uid);
      final isAdmin = userProfile?['roles'] == 'admin';

      if (isAdmin && product == null) {
        // Admin puede crear producto desde código escaneado
        emit(AdminCanCreateProduct(
          code: event.code,
          type: event.type,
          existingCode: existingCode,
        ));
        return;
      }

      // Si no se vendió producto, crear el código escaneado normal
      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'content': event.content ?? '',
        'productName': event.productName,
        'productPrice': event.productPrice,
        'scannedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
      };

      emit(CodeScanned(scannedCode, existingCode: existingCode));
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  Future<void> _onSaveScannedCode(
    SaveScannedCode event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const ScannerError(error: 'Usuario no autenticado'));
        return;
      }

      await FirebaseDatabaseService.saveScannedCode(
        uid: user.uid,
        code: event.code,
        type: event.type,
        content: event.content,
        productName: event.productName,
        productPrice: event.productPrice,
      );

      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'content': event.content ?? '',
        'productName': event.productName,
        'productPrice': event.productPrice,
        'scannedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
      };

      emit(CodeSaved(scannedCode));
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  Future<void> _onLoadScannedCodes(
    LoadScannedCodes event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const ScannerError(error: 'Usuario no autenticado'));
        return;
      }

      // Verificar si el usuario es admin
      final userProfile = await FirebaseDatabaseService.getUserProfile(user.uid);
      final isAdmin = userProfile?['roles'] == 'admin';

      List<Map<String, dynamic>> codes;
      if (isAdmin) {
        // Admin puede ver todos los códigos
        codes = await FirebaseDatabaseService.getAllScannedCodes();
      } else {
        // Usuario normal solo ve sus códigos
        codes = await FirebaseDatabaseService.getScannedCodesHistory(user.uid);
      }

      emit(CodesLoaded(codes));
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  Future<void> _onDeleteScannedCode(
    DeleteScannedCode event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      await FirebaseDatabaseService.deleteScannedCode(event.codeId);
      emit(CodeDeleted(event.codeId));

      // Recargar la lista de códigos después de eliminar
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Verificar si el usuario es admin
        final userProfile = await FirebaseDatabaseService.getUserProfile(user.uid);
        final isAdmin = userProfile?['roles'] == 'admin';

        List<Map<String, dynamic>> codes;
        if (isAdmin) {
          // Admin puede ver todos los códigos
          codes = await FirebaseDatabaseService.getAllScannedCodes();
        } else {
          // Usuario normal solo ve sus códigos
          codes = await FirebaseDatabaseService.getScannedCodesHistory(user.uid);
        }
        emit(CodesLoaded(codes));
      }
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  Future<void> _onCreateProductFromScan(
    CreateProductFromScan event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const ScannerError(error: 'Usuario no autenticado'));
        return;
      }

      // Verificar si el usuario es admin
      final userProfile = await FirebaseDatabaseService.getUserProfile(user.uid);
      final isAdmin = userProfile?['roles'] == 'admin';

      if (!isAdmin) {
        emit(const ScannerError(error: 'Solo los administradores pueden crear productos'));
        return;
      }

      // Crear producto desde código escaneado
      final product = await FirebaseDatabaseService.createProductFromScannedCode(
        code: event.code,
        type: event.type,
        uid: user.uid,
        productName: event.productName,
        productPrice: event.productPrice,
        description: event.description,
      );

      emit(ProductCreated(product));
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

}
