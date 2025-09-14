import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WebQRScannerWidget extends StatefulWidget {
  final Function(String code, String type) onCodeScanned;
  final bool isScanning;

  const WebQRScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.isScanning = true,
  });

  @override
  State<WebQRScannerWidget> createState() => _WebQRScannerWidgetState();
}

class _WebQRScannerWidgetState extends State<WebQRScannerWidget> {
  MobileScannerController? _scannerController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeScanner();
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WebQRScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _scannerController?.start();
      } else {
        _scannerController?.stop();
      }
    }
  }

  Future<void> _initializeScanner() async {
    if (!kIsWeb) return;

    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Esperar a que el controlador esté listo
      await _scannerController!.start();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error inicializando escáner: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = 'Error al acceder a la cámara: ${e.toString()}';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!kIsWeb) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!;
        final now = DateTime.now();

        // Verificar si es el mismo código escaneado recientemente (dentro de 5 segundos)
        if (_lastScannedCode == code &&
            _lastScanTime != null &&
            now.difference(_lastScanTime!).inSeconds < 5) {
          return; // Ignorar escaneo duplicado
        }

        _lastScannedCode = code;
        _lastScanTime = now;

        // Determinar el tipo de código
        String type = 'QR_CODE';
        if (code.startsWith('http')) {
          type = 'URL';
        } else if (code.contains('@')) {
          type = 'EMAIL';
        } else if (code.startsWith('tel:')) {
          type = 'PHONE';
        }

        print('QR Code detectado: $code de tipo: $type');
        widget.onCodeScanned(code, type);
        break; // Solo procesar el primer código detectado
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.8),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'Escáner de códigos QR\nSolo disponible en web',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

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
                  _initializeScanner();
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
              Text(
                'Inicializando cámara...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
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
          // Mobile Scanner
          MobileScanner(controller: _scannerController!, onDetect: _onDetect),
          // Overlay personalizado
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Fondo semi-transparente que cubre toda la pantalla
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),
        // Área transparente en el centro para mostrar el video
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
        // Marco blanco alrededor del área de escaneo
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
                // Esquina superior izquierda
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
                // Esquina superior derecha
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
                // Esquina inferior izquierda
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
                // Esquina inferior derecha
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
}
