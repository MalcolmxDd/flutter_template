import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

mixin CameraControlMixin {
  void pauseCameraForDialog();
  void resumeCameraAfterDialog();
  void pauseCamera();
  void resumeCamera();
}

class WebQRScannerWidget extends StatefulWidget {
  final Function(String code, String type) onCodeScanned;
  final bool isScanning;
  final bool isFlashOn;
  final VoidCallback? onFlashToggle;
  final VoidCallback? onDialogOpened;
  final VoidCallback? onDialogClosed;
  final VoidCallback? onCameraPause;
  final VoidCallback? onCameraResume;

  const WebQRScannerWidget({
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
  State<WebQRScannerWidget> createState() => _WebQRScannerWidgetState();

  // Métodos públicos para controlar la cámara
  static void pauseCamera() {
    _WebQRScannerWidgetState._pauseCameraStatic();
  }

  static void resumeCamera() {
    _WebQRScannerWidgetState._resumeCameraStatic();
  }
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
  static _WebQRScannerWidgetState? _currentInstance;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    if (kIsWeb) {
      _initializeWebScanner();
    } else {
      _initializeMobileScanner();
    }
  }

  @override
  void dispose() {
    _currentInstance = null;
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
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.zIndex = '-1';

      _canvasElement = html.CanvasElement();
      _context = _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D;

      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280, 'min': 640},
          'height': {'ideal': 720, 'min': 480},
          'frameRate': {'ideal': 30, 'min': 15},
          'focusMode': 'continuous',
          'exposureMode': 'continuous',
          'whiteBalanceMode': 'continuous',
        },
      });

      _videoElement!.srcObject = stream;
      await _videoElement!.play();

      if (_videoElement!.srcObject == null) {
        throw Exception('No se pudo asignar el stream de video');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_containerKey.currentContext != null) {
          final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          final videoContainer = html.DivElement()
            ..setAttribute('data-web-qr-scanner', 'true')
            ..style.position = 'fixed'
            ..style.top = '${position.dy}px'
            ..style.left = '${position.dx}px'
            ..style.width = '${size.width}px'
            ..style.height = '${size.height}px'
            ..style.zIndex = '999'
            ..style.overflow = 'hidden'
            ..style.pointerEvents = 'none'
            ..style.borderRadius = '20px'
            ..style.backgroundColor = '#000000'
            ..append(_videoElement!);

          html.document.body!.append(videoContainer);

          _videoElement!.style.width = '100%';
          _videoElement!.style.height = '100%';
          _videoElement!.style.objectFit = 'cover';
          _videoElement!.style.borderRadius = '20px';
          _videoElement!.style.display = 'block';
          _videoElement!.style.visibility = 'visible';
        }
      });

      setState(() {
        _isInitialized = true;
      });

      if (widget.isScanning) {
        _startWebScanning();
      }
    } catch (e) {
      print('Error inicializando escáner web: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = 'Error al acceder a la cámara: ${e.toString()}';

        if (e.toString().contains('NotAllowedError')) {
          _errorMessage = 'Acceso a cámara denegado. Permite el acceso en tu navegador.';
        } else if (e.toString().contains('NotFoundError')) {
          _errorMessage = 'No se encontró cámara. Verifica que tu dispositivo tenga cámara.';
        } else if (e.toString().contains('NotReadableError')) {
          _errorMessage = 'La cámara está siendo usada por otra aplicación.';
        } else if (e.toString().contains('OverconstrainedError')) {
          _errorMessage = 'Configuración incompatible con tu dispositivo.';
        }
      });
    }
  }

  void _startWebScanning() {
    if (!kIsWeb || _videoElement == null || _canvasElement == null || _context == null) {
      return;
    }
    _isScanning = true;
    _scanFrame();
  }

  void _stopWebScanning() {
    _isScanning = false;
  }

  void _scanFrame() {
    if (!_isScanning || _videoElement == null || _canvasElement == null || _context == null) {
      return;
    }

    try {
      if (_videoElement!.readyState < 2) {
        html.window.requestAnimationFrame((_) => _scanFrame());
        return;
      }

      if (_videoElement!.videoWidth == 0 || _videoElement!.videoHeight == 0) {
        html.window.requestAnimationFrame((_) => _scanFrame());
        return;
      }

      _canvasElement!.width = _videoElement!.videoWidth;
      _canvasElement!.height = _videoElement!.videoHeight;
      _context!.drawImage(_videoElement!, 0, 0);

      final imageData = _context!.getImageData(0, 0, _canvasElement!.width!, _canvasElement!.height!);

      if (_isImageQualityGood(imageData)) {
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

      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        print('Escaneando frame: ${imageData.width}x${imageData.height}, Enfocado: $_isFocused');
      }

      html.window.requestAnimationFrame((_) => _scanFrame());
    } catch (e) {
      print('Error en escaneo: $e');
      html.window.requestAnimationFrame((_) => _scanFrame());
    }
  }

  void _detectQRCode(html.ImageData imageData) {
    try {
      final options = js.JsObject(js.context['Object']);
      options['inversionAttempts'] = 'attemptBoth';
      options['greyScaleWeights'] = js.JsObject.jsify([0.2126, 0.7152, 0.0722]);

      final result = js.context.callMethod('jsQR', [imageData.data, imageData.width, imageData.height, options]);

      if (result != null) {
        final code = result['data'].toString();
        if (code.isNotEmpty) {
          print('✅ Código QR detectado: $code');
          _processScannedCode(code, 'QR_CODE');
        }
      }
    } catch (e) {
      // Silenciar errores
    }
  }

  void _detectBarcode(html.ImageData imageData) {
    try {
      if (js.context['ZXing'] == null) return;

      final tempCanvas = html.CanvasElement();
      final tempContext = tempCanvas.getContext('2d') as html.CanvasRenderingContext2D;
      tempCanvas.width = imageData.width;
      tempCanvas.height = imageData.height;
      tempContext.putImageData(imageData, 0, 0);

      final codeReader = js.context['ZXing']['MultiFormatReader'];
      if (codeReader == null) return;

      final reader = js.JsObject(codeReader);
      final hints = js.JsObject(js.context['Object']);
      hints['possibleFormats'] = js.JsObject.jsify(['CODE_128', 'CODE_39', 'EAN_13', 'EAN_8', 'UPC_A', 'UPC_E', 'CODABAR', 'ITF']);
      hints['tryHarder'] = true;
      hints['characterSet'] = 'UTF-8';
      reader['hints'] = hints;

      final luminanceSource = js.JsObject(js.context['ZXing']['HTMLCanvasElementLuminanceSource'], [tempCanvas]);
      final hybridBinarizer = js.JsObject(js.context['ZXing']['HybridBinarizer'], [luminanceSource]);
      final binaryBitmap = js.JsObject(js.context['ZXing']['BinaryBitmap'], [hybridBinarizer]);

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
        // Error normal
      }
    } catch (e) {
      if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
        print('Error en detección de código de barras: $e');
      }
    }
  }

  String _getBarcodeTypeFromFormat(String format) {
    switch (format.toUpperCase()) {
      case 'CODE_128': return 'CODE_128';
      case 'CODE_39': return 'CODE_39';
      case 'EAN_13': return 'EAN_13';
      case 'EAN_8': return 'EAN_8';
      case 'UPC_A': return 'UPC_A';
      case 'UPC_E': return 'UPC_E';
      case 'CODABAR': return 'CODABAR';
      case 'ITF': return 'ITF';
      default: return 'BARCODE';
    }
  }

  bool _isImageQualityGood(html.ImageData imageData) {
    try {
      final data = imageData.data;
      int totalBrightness = 0;
      int pixelCount = 0;

      for (int i = 0; i < data.length; i += 16) {
        if (i + 3 < data.length) {
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
      return averageBrightness > 30 && averageBrightness < 220;
    } catch (e) {
      return true;
    }
  }

  void _attemptFocusAdjustment() {
    if (_videoElement == null) return;

    try {
      final track = _videoElement!.srcObject?.getVideoTracks().first;
      if (track != null) {
        track.applyConstraints({
          'focusMode': 'single-shot',
          'exposureMode': 'single-shot',
        }).then((_) {
          print('Ajustes de enfoque aplicados');
          Future.delayed(const Duration(seconds: 2), () {
            track.applyConstraints({
              'focusMode': 'continuous',
              'exposureMode': 'continuous',
            });
          });
        }).catchError((e) {
          print('Error aplicando ajustes de enfoque: $e');
          _reinitializeWithBasicSettings();
        });
      }
    } catch (e) {
      print('Error en ajuste de enfoque: $e');
      _reinitializeWithBasicSettings();
    }
  }

  void _reinitializeWithBasicSettings() {
    print('Reinicializando cámara con configuraciones básicas...');
    _stopWebCamera();

    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeWebScannerWithBasicSettings();
    });
  }

  Future<void> _initializeWebScannerWithBasicSettings() async {
    if (!kIsWeb) return;

    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _canvasElement = html.CanvasElement();
      _context = _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D;

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_containerKey.currentContext != null) {
          final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
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
          _videoElement!.style.zIndex = '999';
          _videoElement!.style.display = 'block';
          _videoElement!.style.visibility = 'visible';

          html.document.body!.append(_videoElement!);
        }
      });

      setState(() {
        _isInitialized = true;
        _isFocused = false;
      });

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
    if (kIsWeb) return;

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

  void _stopWebCamera() {
    final containers = html.document.querySelectorAll('div[data-web-qr-scanner]');
    for (final container in containers) {
      final videoElement = container.querySelector('video') as html.VideoElement?;
      if (videoElement != null) {
        final stream = videoElement.srcObject;
        if (stream != null) {
          stream.getTracks().forEach((track) => track.stop());
        }
      }
      container.remove();
    }

    _videoElement = null;
    _isScanning = false;
  }

  Future<void> _applyFlashState() async {
    if (!kIsWeb || _videoElement == null) return;

    try {
      final stream = _videoElement!.srcObject;
      if (stream == null) return;

      final videoTrack = stream.getVideoTracks().first;
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
              Text('Inicializando cámara web...', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isInitialized && _videoElement != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.camera_alt, color: Colors.white54, size: 48),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Cámara web activa',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Posicione el código QR o código de barras\nen el área iluminada',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _isScanning ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isScanning ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isScanning ? 'Activo' : 'Pausado',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Cámara web - Escanea códigos QR o códigos de barras',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                ),
              ],
            ),
          ),
          _buildImprovedScannerOverlay(),
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

  Widget _buildImprovedScannerOverlay() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.6,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.8),
                  width: 3,
                ),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildAnimatedCorner(),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildAnimatedCorner(isTopRight: true),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildAnimatedCorner(isBottomLeft: true),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildAnimatedCorner(isBottomRight: true),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  '📱 Cámara Web Activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Posicione el código QR o código de barras\nen el área iluminada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isScanning ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isScanning ? '🔍 Escaneando...' : '⏸️ Pausado',
                    style: TextStyle(
                      color: _isScanning ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAnimatedCorner({bool isTopRight = false, bool isBottomLeft = false, bool isBottomRight = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: isTopRight ? Alignment.bottomLeft : Alignment.topRight,
          end: isTopRight ? Alignment.topRight : Alignment.bottomLeft,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.cyan.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 3),
                  left: BorderSide(color: Colors.white, width: 3),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTopRight ? 0 : 15),
                  topRight: Radius.circular(isTopRight ? 15 : 0),
                  bottomLeft: Radius.circular(isBottomLeft ? 15 : 0),
                  bottomRight: Radius.circular(isBottomRight ? 15 : 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void pauseCamera() {
    if (!kIsWeb) return;

    print('⏸️ Pausando cámara web');
    _stopWebScanning();
    _hideVideoElement();
  }

  void resumeCamera() {
    if (!kIsWeb) return;

    print('▶️ Reanudando cámara web');
    _showVideoElement();
    if (widget.isScanning) {
      _startWebScanning();
    }
  }

  void _hideVideoElement() {
    if (!kIsWeb || _videoElement == null) return;

    // Ocultar el elemento de video
    _videoElement!.style.display = 'none';
    _videoElement!.style.visibility = 'hidden';
    _videoElement!.style.opacity = '0';

    // También ocultar el contenedor
    final containers = html.document.querySelectorAll('div[data-web-qr-scanner]');
    for (final container in containers) {
      container.style.display = 'none';
      container.style.visibility = 'hidden';
      container.style.opacity = '0';
    }
  }

  void _showVideoElement() {
    if (!kIsWeb || _videoElement == null) return;

    // Mostrar el elemento de video
    _videoElement!.style.display = 'block';
    _videoElement!.style.visibility = 'visible';
    _videoElement!.style.opacity = '1';

    // También mostrar el contenedor
    final containers = html.document.querySelectorAll('div[data-web-qr-scanner]');
    for (final container in containers) {
      container.style.display = 'block';
      container.style.visibility = 'visible';
      container.style.opacity = '1';
    }
  }

  // Métodos estáticos para acceso desde fuera del widget
  static void _pauseCameraStatic() {
    // Buscar la instancia actual del estado
    final instance = _getCurrentInstance();
    if (instance != null) {
      instance.pauseCamera();
    }
  }

  static void _resumeCameraStatic() {
    // Buscar la instancia actual del estado
    final instance = _getCurrentInstance();
    if (instance != null) {
      instance.resumeCamera();
    }
  }

  static _WebQRScannerWidgetState? _getCurrentInstance() {
    return _currentInstance;
  }
}