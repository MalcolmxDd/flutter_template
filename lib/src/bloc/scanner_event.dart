part of 'scanner_bloc.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object> get props => [];
}

class ScanCode extends ScannerEvent {
  final String code;
  final String type;
  final String? content;

  const ScanCode({
    required this.code,
    required this.type,
    this.content,
  });

  @override
  List<Object> get props => [code, type, content ?? ''];
}

class SaveScannedCode extends ScannerEvent {
  final String code;
  final String type;
  final String? content;

  const SaveScannedCode({
    required this.code,
    required this.type,
    this.content,
  });

  @override
  List<Object> get props => [code, type, content ?? ''];
}

class LoadScannedCodes extends ScannerEvent {}

class DeleteScannedCode extends ScannerEvent {
  final String codeId;

  const DeleteScannedCode({required this.codeId});

  @override
  List<Object> get props => [codeId];
}

class SyncWithServer extends ScannerEvent {}
