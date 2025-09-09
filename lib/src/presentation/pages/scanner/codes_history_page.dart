import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_template/src/services/firebase_database_service.dart';

class CodesHistoryPage extends StatefulWidget {
  const CodesHistoryPage({super.key});

  @override
  State<CodesHistoryPage> createState() => _CodesHistoryPageState();
}

class _CodesHistoryPageState extends State<CodesHistoryPage> {
  String _filterType = 'all';
  bool _showOnlyUnsynced = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    context.read<ScannerBloc>().add(LoadScannedCodes());
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await FirebaseDatabaseService.getUserProfile(user.uid);
        setState(() {
          _isAdmin = userProfile?['roles'] == 'admin';
        });
      }
    } catch (e) {
      // Si hay error, mantener como usuario normal
      setState(() {
        _isAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshCodes() {
    context.read<ScannerBloc>().add(LoadScannedCodes());
  }


  List<Map<String, dynamic>> _filterCodes(List<Map<String, dynamic>> codes) {
    List<Map<String, dynamic>> filteredCodes = List.from(codes);

    // Filtrar por tipo
    if (_filterType != 'all') {
      filteredCodes = filteredCodes
          .where((code) => code['type'] == _filterType)
          .toList();
    }

    // Filtrar por estado de sincronización
    if (_showOnlyUnsynced) {
      filteredCodes = filteredCodes
          .where((code) => code['isSynced'] == 0)
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      filteredCodes = filteredCodes.where((code) {
        final searchTerm = _searchController.text.toLowerCase();
        return code['code'].toString().toLowerCase().contains(searchTerm) ||
            code['type'].toString().toLowerCase().contains(searchTerm);
      }).toList();
    }

    return filteredCodes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Códigos'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCodes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros y búsqueda
          _buildFiltersSection(),
          // Lista de códigos
          Expanded(child: _buildCodesList()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar códigos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Filtros
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // En pantallas pequeñas, mostrar en columna
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _filterType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Código',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Todos'),
                        ),
                        const DropdownMenuItem(
                          value: 'QR',
                          child: Text('QR Code'),
                        ),
                        const DropdownMenuItem(
                          value: 'CODE128',
                          child: Text('Code 128'),
                        ),
                        const DropdownMenuItem(
                          value: 'CODE39',
                          child: Text('Code 39'),
                        ),
                        const DropdownMenuItem(
                          value: 'EAN13',
                          child: Text('EAN-13'),
                        ),
                        const DropdownMenuItem(
                          value: 'EAN8',
                          child: Text('EAN-8'),
                        ),
                        const DropdownMenuItem(
                          value: 'UPCA',
                          child: Text('UPC-A'),
                        ),
                        const DropdownMenuItem(
                          value: 'UPCE',
                          child: Text('UPC-E'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Checkbox para mostrar solo no sincronizados
                    Row(
                      children: [
                        Checkbox(
                          value: _showOnlyUnsynced,
                          onChanged: (value) {
                            setState(() {
                              _showOnlyUnsynced = value!;
                            });
                          },
                        ),
                        const Expanded(child: Text('Solo no sincronizados')),
                      ],
                    ),
                  ],
                );
              } else {
                // En pantallas grandes, mostrar en fila
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Código',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos'),
                          ),
                          const DropdownMenuItem(
                            value: 'QR',
                            child: Text('QR Code'),
                          ),
                          const DropdownMenuItem(
                            value: 'CODE128',
                            child: Text('Code 128'),
                          ),
                          const DropdownMenuItem(
                            value: 'CODE39',
                            child: Text('Code 39'),
                          ),
                          const DropdownMenuItem(
                            value: 'EAN13',
                            child: Text('EAN-13'),
                          ),
                          const DropdownMenuItem(
                            value: 'EAN8',
                            child: Text('EAN-8'),
                          ),
                          const DropdownMenuItem(
                            value: 'UPCA',
                            child: Text('UPC-A'),
                          ),
                          const DropdownMenuItem(
                            value: 'UPCE',
                            child: Text('UPC-E'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Checkbox para mostrar solo no sincronizados
                    Row(
                      children: [
                        Checkbox(
                          value: _showOnlyUnsynced,
                          onChanged: (value) {
                            setState(() {
                              _showOnlyUnsynced = value!;
                            });
                          },
                        ),
                        const Text('Solo no sincronizados'),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodesList() {
    return BlocBuilder<ScannerBloc, ScannerState>(
      builder: (context, state) {
        if (state is ScannerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CodesLoaded) {
          final filteredCodes = _filterCodes(state.codes);

          if (filteredCodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showOnlyUnsynced
                        ? Icons.cloud_done
                        : Icons.qr_code_scanner_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyUnsynced
                        ? 'No hay códigos pendientes de sincronización'
                        : 'No hay códigos que coincidan con los filtros',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCodes.length,
            itemBuilder: (context, index) {
              final code = filteredCodes[index];
              return _buildCodeCard(code);
            },
          );
        } else if (state is ScannerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshCodes,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Cargando códigos...'));
      },
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> code) {
    final isSynced = code['isSynced'] == 1;
    final scannedAt = code['scannedAt'];
    DateTime timestamp;
    
    if (scannedAt is int) {
      // Firebase timestamp en milliseconds
      timestamp = DateTime.fromMillisecondsSinceEpoch(scannedAt);
    } else if (scannedAt is String) {
      try {
        timestamp = DateTime.parse(scannedAt);
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[50],
      child: ExpansionTile(
        leading: Icon(
          code['type'] == 'QR' ? Icons.qr_code : Icons.qr_code_2,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          code['code']?.toString() ?? 'Código no disponible',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: _isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo: ${code['type']?.toString() ?? 'N/A'}'),
                  if (code['username'] != null)
                    Text(
                      'Usuario: ${code['username']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else if (code['userInfo'] != null)
                    Text(
                      'Usuario: ${code['userInfo']['username'] ?? code['userInfo']['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else if (code['userId'] != null)
                    Text(
                      'Usuario ID: ${code['userId']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              )
            : Text('Tipo: ${code['type']?.toString() ?? 'N/A'}'),
        trailing: Text(
          _formatTimeDifference(difference),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Código completo: '),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          code['code']?.toString() ?? 'Código no disponible',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Escaneado: ${_formatTimestamp(timestamp)}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(code);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Código'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el código "${code['code']}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Eliminar el código de la base de datos
              context.read<ScannerBloc>().add(
                DeleteScannedCode(codeId: code['id']),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código eliminado exitosamente'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
