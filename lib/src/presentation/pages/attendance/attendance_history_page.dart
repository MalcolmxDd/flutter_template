import 'package:flutter/material.dart';
import 'package:flutter_template/src/data/database_helper.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final List<String> userRoles;

  const AttendanceHistoryPage({super.key, required this.userRoles});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  Future<List<Map<String, dynamic>>>? _future;

  bool get _isAdmin => widget.userRoles.contains('admin');

  @override
  void initState() {
    super.initState();
    _initDefaultRange();
    _load();
  }

  void _initDefaultRange() {
    final now = DateTime.now();
    // Por defecto, guardia: hoy; admin: últimos 7 días
    if (_isAdmin) {
      _fromDate = now.subtract(const Duration(days: 7));
      _toDate = now;
    } else {
      _fromDate = DateTime(now.year, now.month, now.day);
      _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  void _load() {
    setState(() {
      _future = _db.getAttendanceWithPerson(
        from: _fromDate,
        to: _toDate,
        rut: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
    });
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _load();
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final initial = _toDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(
        () => _toDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        ),
      );
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencias'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin asistencias en el período'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) => _buildItem(data[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por RUT...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Filtrar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isAdmin)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fromDate == null
                          ? 'Desde'
                          : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _toDate == null
                          ? 'Hasta'
                          : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final rut = item['rut'] ?? '';
    final fullName = item['fullName'] ?? 'Desconocido';
    final occupation = item['occupation'] ?? '—';
    final ts = DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now();
    final deviceId = item['deviceId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.how_to_reg),
        title: Text(fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RUT: $rut'),
            Text('Ocupación: $occupation'),
            Text('Fecha: ${_fmt(ts)} • Dispositivo: $deviceId'),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  String _fmt(DateTime ts) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(ts.day)}/${two(ts.month)}/${ts.year} ${two(ts.hour)}:${two(ts.minute)}';
  }
}
