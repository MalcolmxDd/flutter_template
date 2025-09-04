import 'package:flutter/material.dart';
import 'package:flutter_template/src/presentation/widgets/profile_info_card.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  final List<String> userRoles;

  const ProfilePage({super.key, required this.username, required this.userRoles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = userRoles.contains('admin');

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: isAdmin ? Colors.red : theme.primaryColor,
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              username,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$username@example.com',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.red[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Administrador' : 'Usuario',
                style: TextStyle(
                  color: isAdmin ? Colors.red[800] : Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const ProfileInfoCard(
              icon: Icons.calendar_today,
              label: 'Miembro desde',
              value: 'Septiembre 2025',
            ),
            const ProfileInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: 'No especificada',
            ),
            const ProfileInfoCard(
              icon: Icons.phone_android_outlined,
              label: 'Teléfono',
              value: 'No especificado',
            ),

            // Información adicional para administradores
            if (isAdmin) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const ProfileInfoCard(
                icon: Icons.security_outlined,
                label: 'Nivel de Acceso',
                value: 'Completo',
              ),
              const ProfileInfoCard(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Permisos',
                value: 'Administrador del Sistema',
              ),
              const ProfileInfoCard(
                icon: Icons.supervisor_account_outlined,
                label: 'Usuarios Gestionados',
                value: 'Todos los usuarios',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
