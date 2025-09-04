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

class SyncCompleted extends ScannerState {}

class ScannerError extends ScannerState {
  final String error;

  const ScannerError({required this.error});

  @override
  List<Object> get props => [error];
}
