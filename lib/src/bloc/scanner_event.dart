part of 'scanner_bloc.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object> get props => [];
}

class ScanCode extends ScannerEvent {
  final String code;
  final String type;
  final String deviceId;

  const ScanCode({
    required this.code,
    required this.type,
    required this.deviceId,
  });

  @override
  List<Object> get props => [code, type, deviceId];
}

class SaveScannedCode extends ScannerEvent {
  final String code;
  final String type;
  final String deviceId;

  const SaveScannedCode({
    required this.code,
    required this.type,
    required this.deviceId,
  });

  @override
  List<Object> get props => [code, type, deviceId];
}

class LoadScannedCodes extends ScannerEvent {}

class DeleteScannedCode extends ScannerEvent {
  final int codeId;

  const DeleteScannedCode({required this.codeId});

  @override
  List<Object> get props => [codeId];
}

class SyncWithServer extends ScannerEvent {}
