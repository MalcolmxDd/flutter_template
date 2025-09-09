part of 'scanner_bloc.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object> get props => [];
}

class ScannerInitial extends ScannerState {}

class ScannerLoading extends ScannerState {}

class CodeScanned extends ScannerState {
  final Map<String, dynamic> scannedCode;

  const CodeScanned(this.scannedCode);

  @override
  List<Object> get props => [scannedCode];
}

class CodeSaved extends ScannerState {
  final Map<String, dynamic> scannedCode;

  const CodeSaved(this.scannedCode);

  @override
  List<Object> get props => [scannedCode];
}

class CodesLoaded extends ScannerState {
  final List<Map<String, dynamic>> codes;

  const CodesLoaded(this.codes);

  @override
  List<Object> get props => [codes];
}

class CodeDeleted extends ScannerState {
  final int deletedCodeId;

  const CodeDeleted(this.deletedCodeId);

  @override
  List<Object> get props => [deletedCodeId];
}

class SyncCompleted extends ScannerState {}

class ScannerError extends ScannerState {
  final String error;

  const ScannerError({required this.error});

  @override
  List<Object> get props => [error];
}

// Nuevo: RUT detectado y persona encontrada en BD
class RutDetected extends ScannerState {
  final String rut;
  final Map<String, dynamic> person;
  final String sourceCode;
  final String deviceId;

  const RutDetected({
    required this.rut,
    required this.person,
    required this.sourceCode,
    required this.deviceId,
  });

  @override
  List<Object> get props => [rut, person, sourceCode, deviceId];
}

// Nuevo: persona no encontrada
class PersonNotFound extends ScannerState {
  final String rut;

  const PersonNotFound(this.rut);

  @override
  List<Object> get props => [rut];
}

// Nuevo: asistencia registrada
class AttendanceRecorded extends ScannerState {
  final Map<String, dynamic> attendance;

  const AttendanceRecorded(this.attendance);

  @override
  List<Object> get props => [attendance];
}
