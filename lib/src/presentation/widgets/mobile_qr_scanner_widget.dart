import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

mixin CameraControlMixin {
  void pauseCameraForDialog();
  void resumeCameraAfterDialog();
  void pauseCamera();
  void resumeCamera();
}

class MobileQRScannerWidget extends StatefulWidget {
  final Function(String code, String type) onCodeScanned;
  final bool isScanning;
  final bool isFlashOn;
  final VoidCallback? onFlashToggle;
  final VoidCallback? onDialogOpened;
  final VoidCallback? onDialogClosed;
  final VoidCallback? onCameraPause;
  final VoidCallback? onCameraResume;

  const MobileQRScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.isScanning = true,
    this.isFlashOn = false,
    this.onFlashToggle,
    this.onDialogOpened,
    this.onDialogClosed,
    this.onCameraPause,
    this.onCameraResume,
  });

  @override
  State<MobileQRScannerWidget> createState() => _MobileQRScannerWidgetState();

  // Métodos públicos para controlar la cámara
  static void pauseCamera() {
    _MobileQRScannerWidgetState._pauseCameraStatic();
  }

  static void resumeCamera() {
    _MobileQRScannerWidgetState._resumeCameraStatic();
  }
}

class _MobileQRScannerWidgetState extends State<MobileQRScannerWidget> {
  MobileScannerController? _scannerController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static _MobileQRScannerWidgetState? _currentInstance;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    _initializeMobileScanner();
  }

  @override
  void dispose() {
    _currentInstance = null;
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MobileQRScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _scannerController?.start();
      } else {
        _scannerController?.stop();
      }
    }

    if (widget.isFlashOn != oldWidget.isFlashOn) {
      _applyFlashState();
    }
  }

  Future<void> _initializeMobileScanner() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      await _scannerController!.start();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error inicializando escáner móvil: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = 'Error al acceder a la cámara: ${e.toString()}';
      });
    }
  }

  void _processScannedCode(String code, String type) {
    final now = DateTime.now();

    if (_lastScannedCode == code && _lastScanTime != null && now.difference(_lastScanTime!).inSeconds < 5) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    if (type == 'QR_CODE') {
      if (code.startsWith('http')) {
        type = 'URL';
      } else if (code.contains('@')) {
        type = 'EMAIL';
      } else if (code.startsWith('tel:')) {
        type = 'PHONE';
      }
    }

    print('Código detectado: $code de tipo: $type');

    // Pausar la cámara al detectar un código
    widget.onCameraPause?.call();

    widget.onCodeScanned(code, type);
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final type = _getBarcodeType(barcode.type);
        _processScannedCode(barcode.rawValue!, type);
        break;
      }
    }
  }

  String _getBarcodeType(BarcodeType type) {
    return type.name.toUpperCase();
  }

  Future<void> _applyFlashState() async {
    if (_scannerController == null) return;

    try {
      if (widget.isFlashOn) {
        await _scannerController!.toggleTorch();
      } else {
        await _scannerController!.toggleTorch();
      }
      print('Flash ${widget.isFlashOn ? 'activado' : 'desactivado'}');
    } catch (e) {
      print('Error al aplicar estado del flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Error al acceder a la cámara',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeMobileScanner();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _scannerController == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.8),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Inicializando cámara...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          MobileScanner(controller: _scannerController!, onDetect: _onDetect),
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 3),
                        left: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 3),
                        right: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 3),
                        left: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 3),
                        right: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void pauseCamera() {
    print('⏸️ Pausando cámara móvil');
    _scannerController?.stop();
  }

  void resumeCamera() {
    print('▶️ Reanudando cámara móvil');
    _scannerController?.start();
  }

  // Métodos estáticos para acceso desde fuera del widget
  static void _pauseCameraStatic() {
    final instance = _getCurrentInstance();
    if (instance != null) {
      instance.pauseCamera();
    }
  }

  static void _resumeCameraStatic() {
    final instance = _getCurrentInstance();
    if (instance != null) {
      instance.resumeCamera();
    }
  }

  static _MobileQRScannerWidgetState? _getCurrentInstance() {
    return _currentInstance;
  }
}