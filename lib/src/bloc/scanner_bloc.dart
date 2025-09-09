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
    on<ConfirmAttendance>(_onConfirmAttendance);
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

      // Intentar extraer RUT desde el código escaneado y consultar persona
      final String? rut = _extractRutFromString(event.code);
      if (rut != null) {
        final person = await _databaseHelper.getPersonByRut(rut);
        if (person != null) {
          emit(
            RutDetected(
              rut: rut,
              person: person,
              sourceCode: event.code,
              deviceId: event.deviceId,
            ),
          );
          return;
        } else {
          emit(PersonNotFound(rut));
        }
      }

      // Intentar sincronizar automáticamente
      add(SyncWithServer());
    } catch (e) {
      emit(ScannerError(error: e.toString()));
    }
  }

  // Extrae RUT chileno desde URLs/cadenas comunes de QR de cédulas
  // Soporta formatos con puntos y guion, y también sin puntos
  String? _extractRutFromString(String input) {
    // 1) Intentar RUT con puntos y guion: 12.345.678-5 o 1.234.567-8
    final RegExp rutFormat = RegExp(r'[0-9]{1,2}(?:\.[0-9]{3}){2}-[0-9Kk]');
    final match1 = rutFormat.firstMatch(input);
    if (match1 != null) {
      return match1.group(0)!.toUpperCase();
    }

    // 2) Intentar RUT sin puntos, con guion: 12345678-5
    final RegExp rutSimple = RegExp(r'\b([0-9]{7,9}-[0-9Kk])\b');
    final match2 = rutSimple.firstMatch(input);
    if (match2 != null) {
      return match2.group(1)!.toUpperCase();
    }

    // 3) Param/fragment en URL como rut=12345678-5
    final RegExp rutParam = RegExp(
      r'[?&]rut=([0-9]{7,9}-[0-9Kk])',
      caseSensitive: false,
    );
    final match3 = rutParam.firstMatch(input);
    if (match3 != null) {
      return match3.group(1)!.toUpperCase();
    }

    return null;
  }

  Future<void> _onConfirmAttendance(
    ConfirmAttendance event,
    Emitter<ScannerState> emit,
  ) async {
    try {
      final attendance = {
        'rut': event.rut,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': event.deviceId,
        'sourceCode': event.sourceCode,
        'isSynced': 0,
      };
      final id = await _databaseHelper.saveAttendance(attendance);
      attendance['id'] = id;
      emit(AttendanceRecorded(attendance));
    } catch (e) {
      emit(ScannerError(error: 'No se pudo registrar asistencia: $e'));
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
