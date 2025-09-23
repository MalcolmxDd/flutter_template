import 'package:flutter/material.dart';

class WebQRScannerWidget extends StatefulWidget {
  final Function(String code, String type) onCodeScanned;
  final bool isScanning;
  final bool isFlashOn;
  final VoidCallback? onFlashToggle;

  const WebQRScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.isScanning = true,
    this.isFlashOn = false,
    this.onFlashToggle,
  });

  @override
  State<WebQRScannerWidget> createState() => _WebQRScannerWidgetState();
}

class _WebQRScannerWidgetState extends State<WebQRScannerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(); // Stub for non-web platforms
  }
}