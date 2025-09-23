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
  final String? productName;
  final double? productPrice;
  final bool checkExisting;

  const ScanCode({
    required this.code,
    required this.type,
    this.content,
    this.productName,
    this.productPrice,
    this.checkExisting = false,
  });

  @override
  List<Object> get props => [code, type, content ?? '', productName ?? '', productPrice ?? 0.0, checkExisting];
}

class SaveScannedCode extends ScannerEvent {
  final String code;
  final String type;
  final String? content;
  final String? productName;
  final double? productPrice;

  const SaveScannedCode({
    required this.code,
    required this.type,
    this.content,
    this.productName,
    this.productPrice,
  });

  @override
  List<Object> get props => [code, type, content ?? '', productName ?? '', productPrice ?? 0.0];
}

class LoadScannedCodes extends ScannerEvent {}

class DeleteScannedCode extends ScannerEvent {
  final String codeId;

  const DeleteScannedCode({required this.codeId});

  @override
  List<Object> get props => [codeId];
}

class SyncWithServer extends ScannerEvent {}
