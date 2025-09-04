import 'package:flutter/material.dart';

class DashboardGrid extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onUsersManagementTap;

  const DashboardGrid({
    super.key,
    required this.isAdmin,
    this.onUsersManagementTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return _buildAdminGrid(context);
    } else {
      return _buildUserGrid(context);
    }
  }

  Widget _buildAdminGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.people_outline,
          label: 'Gestionar Usuarios',
          color: Colors.blue,
          onTap: onUsersManagementTap, // Usar el callback directamente
        ),
        _buildDashboardCard(
          context,
          icon: Icons.analytics_outlined,
          label: 'Estadísticas',
          color: Colors.green,
          onTap: () {},
        ),
        _buildDashboardCard(
          context,
          icon: Icons.settings_system_daydream_outlined,
          label: 'Configuración del Sistema',
          color: Colors.orange,
          onTap: () {},
        ),
        _buildDashboardCard(
          context,
          icon: Icons.security_outlined,
          label: 'Seguridad',
          color: Colors.red,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildUserGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.bar_chart,
          label: 'Estadísticas',
          color: Colors.orange,
          onTap: () {},
        ),
        _buildDashboardCard(
          context,
          icon: Icons.history,
          label: 'Actividad Reciente',
          color: Colors.green,
          onTap: () {},
        ),
        _buildDashboardCard(
          context,
          icon: Icons.content_paste,
          label: 'Reportes',
          color: Colors.blue,
          onTap: () {},
        ),
        _buildDashboardCard(
          context,
          icon: Icons.people_outline,
          label: 'Clientes',
          color: Colors.purple,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
