import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/inventory_bloc.dart';
import 'package:flutter_template/src/presentation/pages/add_edit_product_page.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(LoadInventory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEditProduct(null),
          ),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InventoryLoaded) {
            return _buildProductsList(state.products);
          } else if (state is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<InventoryBloc>().add(LoadInventory()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('No hay productos para mostrar'));
        },
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay productos en el inventario'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isLowStock = product.stock < 10;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isLowStock ? Colors.orange[50] : Colors.grey[50],
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLowStock ? Colors.orange : Colors.blue,
              child: Icon(
                Icons.inventory,
                color: Colors.white,
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.orange[800] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio: \$${product.price.toStringAsFixed(2)}'),
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    color: isLowStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (product.description != null && product.description!.isNotEmpty)
                  Text('Descripción: ${product.description}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleProductAction(value, product),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _navigateToAddEditProduct(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  void _navigateToAddEditProduct(Product? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductPage(product: product),
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (product.id != null) {
                context.read<InventoryBloc>().add(DeleteProduct(id: product.id!));
              }
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}