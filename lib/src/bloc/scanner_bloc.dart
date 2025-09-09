import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc() : super(ScannerInitial()) {
    on<ScanCode>(_onScanCode);
    on<SaveScannedCode>(_onSaveScannedCode);
    on<LoadScannedCodes>(_onLoadScannedCodes);
    on<DeleteScannedCode>(_onDeleteScannedCode);
  }

  Future<void> _onScanCode(ScanCode event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const ScannerError(error: 'Usuario no autenticado'));
        return;
      }

      // Guardar el código escaneado en Firebase
      await FirebaseDatabaseService.saveScannedCode(
        uid: user.uid,
        code: event.code,
        type: event.type,
        content: event.content,
      );

      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'content': event.content,
        'scannedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
      };

      emit(CodeScanned(scannedCode));
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
      );

      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'content': event.content,
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

}
