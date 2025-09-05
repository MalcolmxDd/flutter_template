import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_template/src/data/database_helper.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final DatabaseHelper _databaseHelper;

  ScannerBloc(this._databaseHelper) : super(ScannerInitial()) {
    on<ScanCode>(_onScanCode);
    on<SaveScannedCode>(_onSaveScannedCode);
    on<LoadScannedCodes>(_onLoadScannedCodes);
    on<DeleteScannedCode>(_onDeleteScannedCode);
    on<SyncWithServer>(_onSyncWithServer);
  }

  Future<void> _onScanCode(ScanCode event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading());
    try {
      // Guardar el código escaneado localmente
      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': event.deviceId,
        'isSynced': false,
      };

      final id = await _databaseHelper.saveScannedCode(scannedCode);
      scannedCode['id'] = id;

      emit(CodeScanned(scannedCode));

      // Intentar sincronizar automáticamente
      add(SyncWithServer());
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
      final scannedCode = {
        'code': event.code,
        'type': event.type,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': event.deviceId,
        'isSynced': false,
      };

      final id = await _databaseHelper.saveScannedCode(scannedCode);
      scannedCode['id'] = id;

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
      final codes = await _databaseHelper.getAllScannedCodes();
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
      await _databaseHelper.deleteScannedCode(event.codeId);
      emit(CodeDeleted(event.codeId));
      
      // Recargar la lista de códigos después de eliminar
      final codes = await _databaseHelper.getAllScannedCodes();
      emit(CodesLoaded(codes));
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  Future<void> _onSyncWithServer(
    SyncWithServer event,
    Emitter<ScannerState> emit,
  ) async {
    try {
      // Obtener códigos no sincronizados
      final unsyncedCodes = await _databaseHelper.getUnsyncedCodes();

      if (unsyncedCodes.isEmpty) {
        emit(SyncCompleted());
        return;
      }

      // Aquí implementarías la lógica de sincronización con el servidor
      // Por ahora, solo marcamos como sincronizados localmente
      for (final code in unsyncedCodes) {
        await _databaseHelper.markCodeAsSynced(code['id']);
      }

      emit(SyncCompleted());
    } catch (e) {
      emit(ScannerError(error: 'Error de sincronización: $e'));
    }
  }
}
