import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController? _scannerController;
  bool _isScanning = true;
  String _lastScannedCode = '';
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Cargar códigos existentes
    context.read<ScannerBloc>().add(LoadScannedCodes());
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String code = barcode.rawValue ?? '';
      final String type = _getBarcodeType(barcode.type);

      if (code.isNotEmpty) {
        final now = DateTime.now();
        
        // Verificar si es el mismo código escaneado recientemente (dentro de 5 segundos)
        if (_lastScannedCode == code && 
            _lastScanTime != null && 
            now.difference(_lastScanTime!).inSeconds < 5) {
          return; // Ignorar escaneo duplicado
        }

        setState(() {
          _isScanning = false;
          _lastScannedCode = code;
          _lastScanTime = now;
        });

        // Enviar evento para escanear el código
        context.read<ScannerBloc>().add(
          ScanCode(code: code, type: type),
        );

        // Mostrar confirmación
        _showScanConfirmation(code, type);

        // Pausar escaneo por 5 segundos para evitar múltiples escaneos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
        });

        break;
      }
    }
  }

  String _getBarcodeType(BarcodeType type) {
    return type.name.toUpperCase();
  }

  void _showScanConfirmation(String code, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código Escaneado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $type'),
            const SizedBox(height: 8),
            Text('Código: $code'),
            const SizedBox(height: 16),
            const Text(
              'El código ha sido guardado y se sincronizará automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() {
    _scannerController?.toggleTorch();
  }

  void _switchCamera() {
    _scannerController?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Códigos'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(
              _scannerController?.torchEnabled == true
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Área del escáner
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Overlay con guías de escaneo
                _buildScannerOverlay(),
                // Controles del escáner
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: _buildScannerControls(),
                ),
              ],
            ),
          ),
          // Lista de códigos escaneados recientemente
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: _buildRecentCodesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Esquinas del marco
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'scan',
          onPressed: () {
            setState(() {
              _isScanning = !_isScanning;
            });
          },
          backgroundColor: _isScanning ? Colors.green : Colors.red,
          child: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }

  Widget _buildRecentCodesList() {
    return BlocBuilder<ScannerBloc, ScannerState>(
      builder: (context, state) {
        if (state is ScannerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CodesLoaded) {
          if (state.codes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('No hay códigos escaneados aún'),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Códigos Recientes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: state.codes.take(5).length,
                  itemBuilder: (context, index) {
                    final code = state.codes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[50],
                      child: ListTile(
                        leading: Icon(
                          code['type'] == 'QR Code'
                              ? Icons.qr_code
                              : Icons.qr_code_2,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          code['code'],
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${code['type']} • ${_formatTimestamp(code['scannedAt'])}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: const Icon(
                          Icons.cloud_done,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else if (state is ScannerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Error: ${state.error}'),
              ],
            ),
          );
        }
        return const Center(child: Text('Cargando códigos...'));
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Desconocido';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Ahora';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'Desconocido';
    }
  }
}
