import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';
import 'package:flutter_template/src/presentation/widgets/web_qr_scanner_widget.dart';
import 'package:flutter_template/src/presentation/pages/scanner/scanner_product_form_page.dart';
import 'package:flutter_template/src/presentation/pages/scanner/scanner_existing_code_page.dart';
import 'package:flutter_template/src/presentation/pages/inventory_page.dart';
import 'package:flutter_template/src/presentation/pages/main/home_page.dart';
import 'package:flutter/foundation.dart';

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
  bool _isWebFlashOn = false;
  WebQRScannerWidget? _webScannerWidget;

  @override
  void initState() {
    super.initState();

    // Solo inicializar el controlador de móvil si no estamos en web
    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }

    // Cargar códigos existentes
    context.read<ScannerBloc>().add(LoadScannedCodes());

    // Listener para reanudar cámara cuando se regresa a esta página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNavigationListener();
    });
  }

  void _setupNavigationListener() {
    // Este método se ejecutará cuando la página esté visible
    // y configurará un listener para detectar cuando se regresa
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Verificar si estamos regresando de navegación
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      // Estamos en la página actual, verificar si deberíamos reanudar la cámara
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && kIsWeb) {
          // Si estamos en web, reanudar la cámara
          WebQRScannerWidget.resumeCamera();
          setState(() {
            _isScanning = true;
          });
          print('🔄 Cámara reanudada al regresar a la página del escáner');
        }
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _scannerController?.dispose();
    }
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

        // Mostrar formulario para completar información del producto
        _showScanConfirmation(code, type, checkExisting: true);

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

  void _showScanConfirmation(String code, String type, {bool checkExisting = false}) {
    // Enviar evento para escanear el código con verificación de existente
    context.read<ScannerBloc>().add(ScanCode(
      code: code,
      type: type,
      checkExisting: checkExisting,
    ));
  }

  void _showFormWithExistingCode(String code, String type, Map<String, dynamic>? existingCode) {
    // Pausar la cámara antes de navegar
    if (kIsWeb) {
      WebQRScannerWidget.pauseCamera();
      setState(() {
        _isScanning = false;
      });
    }

    if (existingCode != null) {
      // Si el código ya existe, mostrar la información existente
      _showExistingCodeInfo(existingCode);
    } else {
      // Si no existe, mostrar el formulario para crear nuevo
      if (kIsWeb) {
        // En web, navegar a página separada en lugar de modal
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScannerProductFormPage(
              code: code,
              type: type,
              onProductSaved: () {
                // Navegar al inventario después de guardar el producto
                Navigator.of(context).pop(); // Cerrar formulario
                Navigator.of(context).pop(); // Cerrar escáner
                // Navegar al inventario (índice 0 en la navegación principal)
                Navigator.of(context).pushReplacementNamed('/inventory');
              },
            ),
          ),
        );
      } else {
        _showProductFormDialog(code, type);
      }
    }
  }

  void _showExistingCodeInfo(Map<String, dynamic> existingCode) {
    // Pausar la cámara antes de navegar
    if (kIsWeb) {
      WebQRScannerWidget.pauseCamera();
      setState(() {
        _isScanning = false;
      });
    }

    if (kIsWeb) {
      // En web, navegar a página separada en lugar de modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ScannerExistingCodePage(
            existingCode: existingCode,
          ),
        ),
      );
    } else {
      // En móvil, mostrar modal como antes
      final productName = existingCode['productName'] ?? 'Sin nombre';
      final productPrice = existingCode['productPrice'] ?? 0.0;
      final code = existingCode['code'] ?? '';
      final type = existingCode['type'] ?? '';
      final scannedAt = existingCode['scannedAt'];

      String formattedDate = 'Fecha desconocida';
      if (scannedAt != null) {
        try {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(scannedAt);
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          formattedDate = 'Fecha desconocida';
        }
      }

      _showMobileExistingCodeInfo(productName, productPrice, code, type, formattedDate);
    }
  }


  void _showMobileExistingCodeInfo(String productName, double productPrice, String code, String type, String formattedDate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Producto Ya Registrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${productPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Código: $code', style: const TextStyle(fontFamily: 'monospace')),
                  Text('Tipo: $type'),
                  Text('Registrado: $formattedDate'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(String code, String type, {Map<String, dynamic>? existingCode}) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController productPriceController = TextEditingController();

    // Si hay código existente, pre-llenar los campos
    if (existingCode != null) {
      productNameController.text = existingCode['productName'] ?? '';
      productPriceController.text = existingCode['productPrice']?.toString() ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    type == 'QR_CODE' ? Icons.qr_code : Icons.qr_code_2,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Código Escaneado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Información del código
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: $type', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Código: $code', style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Campos del formulario
              TextField(
                controller: productNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto (opcional)',
                  hintText: 'Ej: Coca Cola 350ml',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: productPriceController,
                decoration: InputDecoration(
                  labelText: 'Precio (opcional)',
                  hintText: 'Ej: 1.50',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text(
                'Completa la información del producto para un mejor seguimiento.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // No guardar nada, solo cerrar
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        // Obtener valores de los campos
                        final productName = productNameController.text.trim();
                        final productPrice = double.tryParse(productPriceController.text.trim()) ?? 0.0;

                        // Guardar con información de producto
                        context.read<ScannerBloc>().add(
                          SaveScannedCode(
                            code: code,
                            type: type,
                            content: '',
                            productName: productName.isNotEmpty ? productName : null,
                            productPrice: productPrice > 0 ? productPrice : null,
                          ),
                        );

                        // Mostrar confirmación
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              productName.isNotEmpty && productPrice > 0
                                  ? 'Producto "$productName" guardado con precio \$${productPrice.toStringAsFixed(2)}'
                                  : 'Código guardado ${productName.isNotEmpty ? 'con producto' : 'sin producto'}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }



  void _toggleTorch() {
    if (!kIsWeb) {
      _scannerController?.toggleTorch();
    }
  }

  // Función para alternar flash en web
  void _toggleWebFlash() {
    setState(() {
      _isWebFlashOn = !_isWebFlashOn;
    });
  }

  void _switchCamera() {
    if (!kIsWeb) {
      _scannerController?.switchCamera();
    }
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
              kIsWeb
                  ? (_isWebFlashOn ? Icons.flash_on : Icons.flash_off)
                  : (_scannerController?.torchEnabled == true
                        ? Icons.flash_on
                        : Icons.flash_off),
            ),
            onPressed: kIsWeb ? _toggleWebFlash : _toggleTorch,
            tooltip: 'Alternar flash',
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
              tooltip: 'Cambiar cámara',
            ),
        ],
      ),
      body: Column(
        children: [
          // Área del escáner
          Expanded(child: kIsWeb ? _buildWebScanner() : _buildMobileScanner()),
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

  Widget _buildWebScanner() {
    _webScannerWidget = WebQRScannerWidget(
      onCodeScanned: (code, type) {
        // Procesar el código escaneado desde web
        final now = DateTime.now();

        // Verificar si es el mismo código escaneado recientemente (dentro de 5 segundos)
        if (_lastScannedCode == code &&
            _lastScanTime != null &&
            now.difference(_lastScanTime!).inSeconds < 5) {
          return; // Ignorar escaneo duplicado
        }

        setState(() {
          _lastScannedCode = code;
          _lastScanTime = now;
        });

        // Pausar la cámara inmediatamente al detectar un código
        WebQRScannerWidget.pauseCamera();

        // Mostrar formulario para completar información del producto
        _showScanConfirmation(code, type, checkExisting: true);
      },
      isScanning: _isScanning,
      isFlashOn: _isWebFlashOn,
      onFlashToggle: _toggleWebFlash,
    );

    return _webScannerWidget!;
  }

  Widget _buildMobileScanner() {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onDetect),
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
    return BlocListener<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is CodeAlreadyExists) {
          // Mostrar información del código existente
          _showExistingCodeInfo(state.existingCode);
        } else if (state is CodeScanned) {
          // Mostrar formulario con información del código existente si está disponible
          _showFormWithExistingCode(
            state.scannedCode['code'],
            state.scannedCode['type'],
            state.existingCode,
          );
        } else if (state is AdminCanCreateProduct) {
          // Mostrar formulario para que admin cree producto
          _showAdminProductCreationForm(
            state.code,
            state.type,
            state.existingCode,
          );
        } else if (state is ProductCreated) {
          // Mostrar confirmación de producto creado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${state.product.name}" creado exitosamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is ProductCreationError) {
          // Mostrar error en creación de producto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear producto: ${state.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is SaleSuccess) {
          // Mostrar mensaje de venta exitosa
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta realizada exitosamente. Total: \$${state.sale.total.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is SaleError) {
          // Mostrar mensaje de error en venta
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en venta: ${state.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<ScannerBloc, ScannerState>(
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
        } else if (state is SaleSuccess) {
          // Venta exitosa, mostrar mensaje (ya manejado en listener)
          return const Center(
            child: Text('Venta procesada exitosamente'),
          );
        } else if (state is SaleError) {
          // Error en venta, mostrar mensaje (ya manejado en listener)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Error en venta: ${state.error}'),
              ],
            ),
          );
        }
        return const Center(child: Text('Cargando códigos...'));
      },
    ),
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

  void _showAdminProductCreationForm(String code, String type, Map<String, dynamic>? existingCode) {
    if (kIsWeb) {
      // En web, navegar a página separada en lugar de modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ScannerProductFormPage(
            code: code,
            type: type,
            existingCode: existingCode,
            onProductSaved: () {
              // Volver a la navegación principal después de guardar el producto
              Navigator.of(context).pop(); // Cerrar formulario
              Navigator.of(context).pop(); // Cerrar escáner

              // Volver a la página principal con toda la navegación
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false, // Remover todas las rutas anteriores
              );
            },
          ),
        ),
      );
    } else {
      // En móvil, mostrar modal como antes
      final TextEditingController productNameController = TextEditingController();
      final TextEditingController productPriceController = TextEditingController();
      final TextEditingController descriptionController = TextEditingController();

      // Si hay código existente, pre-llenar los campos
      if (existingCode != null) {
        productNameController.text = existingCode['productName'] ?? '';
        productPriceController.text = existingCode['productPrice']?.toString() ?? '';
      }

      _showMobileAdminProductForm(code, type, productNameController, productPriceController, descriptionController);
    }
  }

  void _showMobileAdminProductForm(
    String code,
    String type,
    TextEditingController productNameController,
    TextEditingController productPriceController,
    TextEditingController descriptionController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Crear Producto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Información del código
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: $type', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Código: $code', style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Campos del formulario
              TextField(
                controller: productNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto *',
                  hintText: 'Ej: Coca Cola 350ml',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: productPriceController,
                decoration: InputDecoration(
                  labelText: 'Precio *',
                  hintText: 'Ej: 1.50',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Bebida gaseosa sabor cola',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Los campos marcados con * son obligatorios.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // No crear producto, solo cerrar
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        // Validar campos obligatorios
                        final productName = productNameController.text.trim();
                        final productPrice = double.tryParse(productPriceController.text.trim()) ?? 0.0;

                        if (productName.isEmpty || productPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor complete los campos obligatorios'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Crear producto
                        context.read<ScannerBloc>().add(
                          CreateProductFromScan(
                            code: code,
                            type: type,
                            productName: productName,
                            productPrice: productPrice,
                            description: descriptionController.text.trim(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Crear Producto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

}
