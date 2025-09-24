import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';

class ScannerProductFormPage extends StatefulWidget {
  final String code;
  final String type;
  final Map<String, dynamic>? existingCode;
  final VoidCallback? onProductSaved;

  const ScannerProductFormPage({
    super.key,
    required this.code,
    required this.type,
    this.existingCode,
    this.onProductSaved,
  });

  @override
  State<ScannerProductFormPage> createState() => _ScannerProductFormPageState();
}

class _ScannerProductFormPageState extends State<ScannerProductFormPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Si hay código existente, pre-llenar los campos
    if (widget.existingCode != null) {
      _productNameController.text = widget.existingCode!['productName'] ?? '';
      _productPriceController.text = widget.existingCode!['productPrice']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productName = _productNameController.text.trim();
    final productPrice = double.tryParse(_productPriceController.text.trim()) ?? 0.0;

    if (productName.isEmpty || productPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos obligatorios (Nombre y Precio)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Crear producto
    context.read<ScannerBloc>().add(
      CreateProductFromScan(
        code: widget.code,
        type: widget.type,
        productName: productName,
        productPrice: productPrice,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  void _saveSimple() {
    // Guardar sin información de producto
    context.read<ScannerBloc>().add(
      SaveScannedCode(
        code: widget.code,
        type: widget.type,
        content: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Código Escaneado'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Botón "Guardar Simple" removido para web
        ],
      ),
      body: BlocListener<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state is ProductCreated) {
            // Mostrar confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Producto "${state.product.name}" creado exitosamente'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Usar callback si está disponible, sino navegar al escáner
            Future.delayed(const Duration(seconds: 2), () {
              if (widget.onProductSaved != null) {
                widget.onProductSaved!();
              } else {
                Navigator.of(context).pop(); // Cerrar esta página
                Navigator.of(context).pop(); // Volver al escáner
              }
            });
          } else if (state is ProductCreationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al crear producto: ${state.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            setState(() {
              _isLoading = false;
            });
          } else if (state is CodeSaved) {
            // Código guardado exitosamente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código guardado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Usar callback si está disponible, sino navegar al escáner
            Future.delayed(const Duration(seconds: 2), () {
              if (widget.onProductSaved != null) {
                widget.onProductSaved!();
              } else {
                Navigator.of(context).pop(); // Cerrar esta página
                Navigator.of(context).pop(); // Volver al escáner
              }
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del código
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.type == 'QR_CODE' ? Icons.qr_code : Icons.qr_code_2,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Información del Código',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Tipo: ${widget.type}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Código: ${widget.code}', style: const TextStyle(fontFamily: 'monospace')),
                    ],
                  ),
                ),

                // Campos del formulario
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Producto *',
                            hintText: 'Ej: Coca Cola 350ml',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre del producto es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _productPriceController,
                          decoration: InputDecoration(
                            labelText: 'Precio *',
                            hintText: 'Ej: 1.50',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixText: '\$ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El precio es obligatorio';
                            }
                            final price = double.tryParse(value.trim());
                            if (price == null || price <= 0) {
                              return 'Ingrese un precio válido mayor a 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción (opcional)',
                            hintText: 'Ej: Bebida gaseosa sabor cola',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            '💡 Los campos marcados con * son obligatorios. Complete la información del producto para registrarlo en el inventario.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop(); // Volver al escáner
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Crear Producto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}