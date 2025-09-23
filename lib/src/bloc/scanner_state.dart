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
  final Map<String, dynamic>? existingCode;

  const CodeScanned(this.scannedCode, {this.existingCode});

  @override
  List<Object> get props => [scannedCode, existingCode ?? {}];
}

class CodeAlreadyExists extends ScannerState {
  final Map<String, dynamic> existingCode;

  const CodeAlreadyExists(this.existingCode);

  @override
  List<Object> get props => [existingCode];
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
  final String deletedCodeId;

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
