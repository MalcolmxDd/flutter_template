import 'package:flutter/material.dart';
import 'package:flutter_template/src/presentation/pages/scanner/codes_history_page.dart';
import 'package:flutter_template/src/presentation/pages/scanner/scanner_page.dart';

class DashboardGrid extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onUsersManagementTap;
  final VoidCallback? onInventoryTap;

  const DashboardGrid({
    super.key,
    required this.isAdmin,
    this.onUsersManagementTap,
    this.onInventoryTap,
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
          icon: Icons.inventory,
          label: 'Inventario',
          color: Colors.purple,
          onTap: onInventoryTap,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.qr_code_scanner,
          label: 'Historial de Escaneos',
          color: Colors.blue,
          onTap: () {
            // Navegar a la página de historial de códigos
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CodesHistoryPage(),
              ),
            );
          },
        ),
        _buildDashboardCard(
          context,
          icon: Icons.people_outline,
          label: 'Gestionar Usuarios',
          color: Colors.green,
          onTap: onUsersManagementTap,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.analytics,
          label: 'Reportes',
          color: Colors.orange,
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
          icon: Icons.qr_code_scanner,
          label: 'Escanear Productos',
          color: Colors.blue,
          onTap: () {
            // Navegar a la página del escáner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScannerPage(),
              ),
            );
          },
        ),
        _buildDashboardCard(
          context,
          icon: Icons.history,
          label: 'Mis Escaneos',
          color: Colors.green,
          onTap: () {
            // Navegar a la página de historial de códigos
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CodesHistoryPage(),
              ),
            );
          },
        ),
        _buildDashboardCard(
          context,
          icon: Icons.inventory,
          label: 'Inventario',
          color: Colors.purple,
          onTap: onInventoryTap,
        ),
        _buildDashboardCard(
          context,
          icon: Icons.point_of_sale,
          label: 'Ventas',
          color: Colors.orange,
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
