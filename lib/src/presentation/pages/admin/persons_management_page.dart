import 'package:flutter/material.dart';
import 'package:flutter_template/src/data/database_helper.dart';

class PersonsManagementPage extends StatefulWidget {
  const PersonsManagementPage({super.key});

  @override
  State<PersonsManagementPage> createState() => _PersonsManagementPageState();
}

class _PersonsManagementPageState extends State<PersonsManagementPage> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _persons = [];
  bool _loading = true;
  bool _onlyActive = true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    setState(() => _loading = true);
    final rows = await _db.getAllPersons(
      isActive: _onlyActive ? true : null,
      searchQuery: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text,
    );
    setState(() {
      _persons = rows;
      _loading = false;
    });
  }

  Future<void> _showPersonDialog({Map<String, dynamic>? person}) async {
    final formKey = GlobalKey<FormState>();
    final rutCtrl = TextEditingController(text: person?['rut'] ?? '');
    final nameCtrl = TextEditingController(text: person?['fullName'] ?? '');
    final occCtrl = TextEditingController(text: person?['occupation'] ?? '');
    bool isActive = (person?['isActive'] ?? 1) == 1;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(person == null ? 'Agregar persona' : 'Editar persona'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: rutCtrl,
                  decoration: const InputDecoration(labelText: 'RUT'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa RUT' : null,
                  readOnly: person != null,
                ),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa nombre' : null,
                ),
                TextFormField(
                  controller: occCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ocupación (opcional)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: isActive,
                  onChanged: (val) => isActive = val,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (person == null) {
                await _db.insertPerson(
                  rut: rutCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  occupation: occCtrl.text.trim().isEmpty
                      ? null
                      : occCtrl.text.trim(),
                  isActive: isActive,
                );
              } else {
                await _db.updatePersonByRut(
                  rut: rutCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  occupation: occCtrl.text.trim().isEmpty
                      ? null
                      : occCtrl.text.trim(),
                  isActive: isActive,
                );
              }
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadPersons();
    }
  }

  Future<void> _confirmDelete(String rut) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar persona'),
        content: Text(
          '¿Seguro que deseas eliminar $rut? Esta acción es permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deletePersonByRut(rut);
      await _loadPersons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar por RUT, nombre u ocupación',
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadPersons();
                              },
                            ),
                    ),
                    onSubmitted: (_) => _loadPersons(),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Solo activos'),
                  selected: _onlyActive,
                  onSelected: (v) {
                    setState(() => _onlyActive = v);
                    _loadPersons();
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showPersonDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _persons.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.separated(
                      itemCount: _persons.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = _persons[i];
                        return ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(p['fullName'] ?? ''),
                          subtitle: Text(
                            '${p['rut']} • ${p['occupation'] ?? 'Sin ocupación'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showPersonDialog(person: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _confirmDelete(p['rut'] as String),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
