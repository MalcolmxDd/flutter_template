import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _isFocused = false;
  int _focusAttempts = 0;
  static const int _maxFocusAttempts = 3;

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

    // Aplicar cambios en el estado del flash
    if (widget.isFlashOn != oldWidget.isFlashOn) {
      _applyFlashState();
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

      // Solicitar acceso a la cámara con configuraciones optimizadas para enfoque
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment', // Cámara trasera
          'width': {
            'ideal': 1920,
            'min': 1280,
          }, // Mayor resolución para mejor detalle
          'height': {'ideal': 1080, 'min': 720},
          'frameRate': {'ideal': 30, 'min': 15}, // Frame rate estable
          'focusMode': 'continuous', // Enfoque continuo si está disponible
          'exposureMode': 'continuous', // Exposición continua
          'whiteBalanceMode': 'continuous', // Balance de blancos continuo
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
          _videoElement!.style.zIndex = '1';

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
        _context == null) {
      return;
    }

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
        _context == null) {
      return;
    }

    try {
      // Verificar si el video está listo y enfocado
      if (_videoElement!.readyState < 2) {
        html.window.requestAnimationFrame((_) => _scanFrame());
        return;
      }

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

      // Verificar la calidad de la imagen antes de detectar
      if (_isImageQualityGood(imageData)) {
        // Detectar tanto códigos QR como códigos de barras
        _detectQRCode(imageData);
        _detectBarcode(imageData);
        _isFocused = true;
        _focusAttempts = 0;
      } else {
        _focusAttempts++;
        if (_focusAttempts >= _maxFocusAttempts) {
          _attemptFocusAdjustment();
          _focusAttempts = 0;
        }
      }

      // Log de depuración reducido
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        print(
          'Escaneando frame: ${imageData.width}x${imageData.height}, Enfocado: $_isFocused',
        );
      }

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
      // Usar jsQR para detectar códigos QR con parámetros optimizados
      final options = js.JsObject(js.context['Object']);
      options['inversionAttempts'] =
          'attemptBoth'; // Intentar ambas orientaciones
      options['greyScaleWeights'] = js.JsObject.jsify([
        0.2126,
        0.7152,
        0.0722,
      ]); // Pesos para conversión a escala de grises

      final result = js.context.callMethod('jsQR', [
        imageData.data,
        imageData.width,
        imageData.height,
        options,
      ]);

      if (result != null) {
        final code = result['data'].toString();
        if (code.isNotEmpty) {
          print('✅ Código QR detectado: $code');
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
      // Verificar si ZXing está disponible
      if (js.context['ZXing'] == null) {
        return;
      }

      // Crear un canvas temporal
      final tempCanvas = html.CanvasElement();
      final tempContext =
          tempCanvas.getContext('2d') as html.CanvasRenderingContext2D;

      tempCanvas.width = imageData.width;
      tempCanvas.height = imageData.height;
      tempContext.putImageData(imageData, 0, 0);

      // Usar ZXing de manera más directa
      final codeReader = js.context['ZXing']['MultiFormatReader'];
      if (codeReader == null) {
        return;
      }

      final reader = js.JsObject(codeReader);

      // Crear hints para los formatos soportados con parámetros optimizados
      final hints = js.JsObject(js.context['Object']);
      hints['possibleFormats'] = js.JsObject.jsify([
        'CODE_128',
        'CODE_39',
        'EAN_13',
        'EAN_8',
        'UPC_A',
        'UPC_E',
        'CODABAR',
        'ITF',
      ]);
      hints['tryHarder'] =
          true; // Intentar más duro para detectar códigos difíciles
      hints['characterSet'] = 'UTF-8'; // Conjunto de caracteres
      reader['hints'] = hints;

      // Crear BinaryBitmap usando la forma correcta de llamar constructores
      final luminanceSource = js.JsObject(
        js.context['ZXing']['HTMLCanvasElementLuminanceSource'],
        [tempCanvas],
      );
      final hybridBinarizer = js.JsObject(
        js.context['ZXing']['HybridBinarizer'],
        [luminanceSource],
      );
      final binaryBitmap = js.JsObject(js.context['ZXing']['BinaryBitmap'], [
        hybridBinarizer,
      ]);

      // Intentar decodificar
      try {
        final result = reader.callMethod('decode', [binaryBitmap]);
        if (result != null) {
          final code = result['text'].toString();
          final format = result['format'].toString();
          print('✅ Código de barras detectado: $code de tipo: $format');
          if (code.isNotEmpty) {
            _processScannedCode(code, _getBarcodeTypeFromFormat(format));
          }
        }
      } catch (decodeError) {
        // Error de decodificación es normal, no hacer nada
      }
    } catch (e) {
      // Solo mostrar errores críticos
      if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
        print('Error en detección de código de barras: $e');
      }
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
      default:
        return 'BARCODE';
    }
  }

  /// Verifica si la calidad de la imagen es buena para detección
  bool _isImageQualityGood(html.ImageData imageData) {
    try {
      final data = imageData.data;
      int totalBrightness = 0;
      int pixelCount = 0;

      // Muestrear cada 4 píxeles para eficiencia
      for (int i = 0; i < data.length; i += 16) {
        // 4 píxeles * 4 canales
        if (i + 3 < data.length) {
          // Calcular luminancia (promedio de RGB)
          final r = data[i];
          final g = data[i + 1];
          final b = data[i + 2];
          final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();
          totalBrightness += luminance;
          pixelCount++;
        }
      }

      if (pixelCount == 0) return false;

      final averageBrightness = totalBrightness / pixelCount;

      // Verificar que la imagen no esté demasiado oscura o brillante
      return averageBrightness > 30 && averageBrightness < 220;
    } catch (e) {
      return true; // Si hay error, asumir que está bien
    }
  }

  /// Intenta ajustar el enfoque de la cámara
  void _attemptFocusAdjustment() {
    if (_videoElement == null) return;

    try {
      // Intentar aplicar constraints de enfoque más estrictos
      final track = _videoElement!.srcObject?.getVideoTracks().first;
      if (track != null) {
        track
            .applyConstraints({
              'focusMode': 'single-shot',
              'exposureMode': 'single-shot',
            })
            .then((_) {
              print('Ajustes de enfoque aplicados');
              // Después de un momento, volver al modo continuo
              Future.delayed(const Duration(seconds: 2), () {
                track.applyConstraints({
                  'focusMode': 'continuous',
                  'exposureMode': 'continuous',
                });
              });
            })
            .catchError((e) {
              print('Error aplicando ajustes de enfoque: $e');
              // Si falla, intentar reinicializar con configuraciones más básicas
              _reinitializeWithBasicSettings();
            });
      }
    } catch (e) {
      print('Error en ajuste de enfoque: $e');
      _reinitializeWithBasicSettings();
    }
  }

  /// Reinicializa la cámara con configuraciones más básicas si el enfoque automático falla
  void _reinitializeWithBasicSettings() {
    print('Reinicializando cámara con configuraciones básicas...');
    _stopWebCamera();

    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeWebScannerWithBasicSettings();
    });
  }

  /// Inicializa el escáner web con configuraciones más básicas para mejor compatibilidad
  Future<void> _initializeWebScannerWithBasicSettings() async {
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

      // Configuraciones más básicas para mejor compatibilidad
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280, 'min': 640},
          'height': {'ideal': 720, 'min': 480},
          'frameRate': {'ideal': 24, 'min': 15},
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
          _videoElement!.style.zIndex = '1';

          // Agregar el video al DOM
          html.document.body!.append(_videoElement!);
        }
      });

      setState(() {
        _isInitialized = true;
        _isFocused = false; // Resetear estado de enfoque
      });

      // Iniciar escaneo si está habilitado
      if (widget.isScanning) {
        _startWebScanning();
      }
    } catch (e) {
      print('Error reinicializando escáner web: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = 'Error al reinicializar la cámara: ${e.toString()}';
      });
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

  /// Aplica el estado del flash a la cámara web
  Future<void> _applyFlashState() async {
    if (!kIsWeb || _videoElement == null) return;

    try {
      final stream = _videoElement!.srcObject;
      if (stream == null) return;

      final videoTrack = stream.getVideoTracks().first;

      // Aplicar constraints para controlar el flash
      await videoTrack.applyConstraints({
        'torch': widget.isFlashOn,
        'exposureMode': widget.isFlashOn ? 'single-shot' : 'continuous',
        'exposureCompensation': widget.isFlashOn ? 1.0 : 0.0,
      });

      print('Flash ${widget.isFlashOn ? 'activado' : 'desactivado'}');
    } catch (e) {
      print('Error al aplicar estado del flash: $e');
    }
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
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    'Cámara activa - Escanea códigos QR o códigos de barras',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                // Indicador de estado del enfoque
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isFocused
                          ? Colors.green.withOpacity(0.8)
                          : Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFocused ? Icons.check_circle : Icons.warning,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFocused ? 'Enfocado' : 'Ajustando enfoque...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón para forzar enfoque
                Positioned(
                  bottom: 20,
                  right: 80,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _attemptFocusAdjustment,
                    backgroundColor: Colors.blue.withOpacity(0.8),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Botón para alternar flash
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: widget.onFlashToggle,
                    backgroundColor: widget.isFlashOn
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.8),
                    child: Icon(
                      widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
