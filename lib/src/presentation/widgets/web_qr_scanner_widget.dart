import 'dart:html' as html;
import 'dart:js' as js;
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
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.CanvasRenderingContext2D? _context;
  bool _isScanning = false;
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeWebScanner();
    } else {
      _initializeMobileScanner();
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _stopWebCamera();
    super.dispose();
  }

  @override
  void didUpdateWidget(WebQRScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        if (kIsWeb) {
          _startWebScanning();
        } else {
          _scannerController?.start();
        }
      } else {
        if (kIsWeb) {
          _stopWebScanning();
        } else {
          _scannerController?.stop();
        }
      }
    }
  }

  Future<void> _initializeMobileScanner() async {
    if (kIsWeb) return;

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

  Future<void> _initializeWebScanner() async {
    if (!kIsWeb) return;

    try {
      // Crear elementos HTML para la cámara
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _canvasElement = html.CanvasElement();
      _context =
          _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D;

      // Solicitar acceso a la cámara
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment', // Cámara trasera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      _videoElement!.srcObject = stream;
      await _videoElement!.play();

      // Posicionar el video en el contenedor correcto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_containerKey.currentContext != null) {
          final RenderBox renderBox =
              _containerKey.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          _videoElement!.style.position = 'fixed';
          _videoElement!.style.top = '${position.dy}px';
          _videoElement!.style.left = '${position.dx}px';
          _videoElement!.style.width = '${size.width}px';
          _videoElement!.style.height = '${size.height}px';
          _videoElement!.style.objectFit = 'cover';
          _videoElement!.style.borderRadius = '20px';
          _videoElement!.style.overflow = 'hidden';
          _videoElement!.style.zIndex = '1000';

          // Agregar el video al DOM
          html.document.body!.append(_videoElement!);
        }
      });

      setState(() {
        _isInitialized = true;
      });

      // Iniciar escaneo si está habilitado
      if (widget.isScanning) {
        _startWebScanning();
      }
    } catch (e) {
      print('Error inicializando escáner web: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = 'Error al acceder a la cámara: ${e.toString()}';
      });
    }
  }

  void _startWebScanning() {
    if (!kIsWeb ||
        _videoElement == null ||
        _canvasElement == null ||
        _context == null)
      return;

    _isScanning = true;
    _scanFrame();
  }

  void _stopWebScanning() {
    _isScanning = false;
  }

  void _scanFrame() {
    if (!_isScanning ||
        _videoElement == null ||
        _canvasElement == null ||
        _context == null)
      return;

    try {
      // Configurar el canvas con el tamaño del video
      _canvasElement!.width = _videoElement!.videoWidth;
      _canvasElement!.height = _videoElement!.videoHeight;

      // Dibujar el frame actual del video en el canvas
      _context!.drawImage(_videoElement!, 0, 0);

      // Obtener los datos de imagen
      final imageData = _context!.getImageData(
        0,
        0,
        _canvasElement!.width!,
        _canvasElement!.height!,
      );

      // Detectar tanto códigos QR como códigos de barras
      _detectQRCode(imageData);
      _detectBarcode(imageData);

      // Continuar escaneando
      html.window.requestAnimationFrame((_) => _scanFrame());
    } catch (e) {
      print('Error en escaneo: $e');
      // Continuar escaneando incluso si hay error
      html.window.requestAnimationFrame((_) => _scanFrame());
    }
  }

  void _detectQRCode(html.ImageData imageData) {
    try {
      // Usar jsQR para detectar códigos QR
      final options = js.JsObject(js.context['Object']);
      options['inversionAttempts'] = 'dontInvert';

      final result = js.context.callMethod('jsQR', [
        imageData.data,
        imageData.width,
        imageData.height,
        options,
      ]);

      if (result != null) {
        final code = result['data'].toString();
        if (code.isNotEmpty) {
          _processScannedCode(code, 'QR_CODE');
        }
      }
    } catch (e) {
      // Silenciar errores de detección para no spamear la consola
      // print('Error en detección QR: $e');
    }
  }

  void _detectBarcode(html.ImageData imageData) {
    try {
      // Usar SimpleBarcode para detectar códigos de barras
      if (js.context['SimpleBarcode'] != null) {
        final result = js.context['SimpleBarcode'].callMethod('scan', [
          _canvasElement,
          imageData.data,
          imageData.width,
          imageData.height,
        ]);

        if (result != null && result['code'] != null) {
          final code = result['code'].toString();
          final format = result['format']?.toString() ?? 'BARCODE';
          if (code.isNotEmpty) {
            _processScannedCode(code, _getBarcodeTypeFromFormat(format));
          }
        }
      }
    } catch (e) {
      // Silenciar errores de detección para no spamear la consola
      // print('Error en detección de código de barras: $e');
    }
  }

  String _getBarcodeTypeFromFormat(String format) {
    switch (format.toUpperCase()) {
      case 'CODE_128':
        return 'CODE_128';
      case 'CODE_39':
        return 'CODE_39';
      case 'EAN_13':
        return 'EAN_13';
      case 'EAN_8':
        return 'EAN_8';
      case 'UPC_A':
        return 'UPC_A';
      case 'UPC_E':
        return 'UPC_E';
      case 'CODABAR':
        return 'CODABAR';
      case 'ITF':
        return 'ITF';
      case 'PDF_417':
        return 'PDF_417';
      case 'AZTEC':
        return 'AZTEC';
      case 'DATA_MATRIX':
        return 'DATA_MATRIX';
      default:
        return 'BARCODE';
    }
  }

  void _processScannedCode(String code, String type) {
    final now = DateTime.now();

    // Verificar si es el mismo código escaneado recientemente (dentro de 5 segundos)
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 5) {
      return; // Ignorar escaneo duplicado
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    // Si es un QR_CODE, determinar el tipo de contenido
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
    widget.onCodeScanned(code, type);
  }

  void _onDetect(BarcodeCapture capture) {
    if (kIsWeb) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final type = _getBarcodeType(barcode.type);
        _processScannedCode(barcode.rawValue!, type);
        break; // Solo procesar el primer código detectado
      }
    }
  }

  String _getBarcodeType(BarcodeType type) {
    return type.name.toUpperCase();
  }

  void _stopWebCamera() {
    if (_videoElement != null) {
      final stream = _videoElement!.srcObject;
      if (stream != null) {
        stream.getTracks().forEach((track) => track.stop());
      }
      _videoElement!.remove();
      _videoElement = null;
    }
    _isScanning = false;
  }

  @override
  Widget build(BuildContext context) {
    // Para móvil, usar mobile_scanner
    if (!kIsWeb) {
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
            MobileScanner(controller: _scannerController!, onDetect: _onDetect),
            _buildScannerOverlay(),
          ],
        ),
      );
    }

    // Para web, usar implementación nativa
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
                  _initializeWebScanner();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _videoElement == null) {
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
                'Inicializando cámara web...',
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
          // Contenedor principal con key para posicionar el video
          Container(
            key: _containerKey,
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Cámara activa - Escanea códigos QR o códigos de barras',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
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
