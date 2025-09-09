import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/theme_bloc.dart';
import 'package:flutter_template/src/bloc/theme_event.dart';
import 'package:flutter_template/src/bloc/theme_state.dart';
import 'package:flutter_template/src/presentation/widgets/settings_section_title.dart';
import 'package:flutter_template/src/presentation/widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  final List<String> userRoles;

  const SettingsPage({super.key, required this.userRoles});

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRoles.contains('admin');

    return Scaffold(
      body: ListView(
        children: [
          const SettingsSectionTitle(title: 'General'),
          const SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Gestiona tus alertas',
          ),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Habilita el tema oscuro'),
                secondary: const Icon(Icons.palette_outlined),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  context.read<ThemeBloc>().add(
                    ThemeChanged(isDarkMode: value),
                  );
                },
              );
            },
          ),
          const Divider(),
          const SettingsSectionTitle(title: 'Cuenta'),
          const SettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacidad y Seguridad',
            subtitle: 'Controla tus datos',
          ),
          const SettingsTile(
            icon: Icons.language_outlined,
            title: 'Idioma',
            subtitle: 'Selecciona tu idioma',
          ),

          // Configuraciones específicas para administradores
          if (isAdmin) ...[
            const Divider(),
            const SettingsSectionTitle(title: 'Administración'),
            const SettingsTile(
              icon: Icons.security_outlined,
              title: 'Configuración de Seguridad',
              subtitle: 'Configuraciones avanzadas de seguridad',
            ),
            const SettingsTile(
              icon: Icons.backup_outlined,
              title: 'Respaldo y Restauración',
              subtitle: 'Gestiona respaldos del sistema',
            ),
            const SettingsTile(
              icon: Icons.analytics_outlined,
              title: 'Logs del Sistema',
              subtitle: 'Revisa la actividad del sistema',
            ),
            const SettingsTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Permisos y Roles',
              subtitle: 'Gestiona permisos de usuarios',
            ),
          ],

          const Divider(),
          const SettingsSectionTitle(title: 'Soporte'),
          const SettingsTile(
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
          ),
          const SettingsTile(icon: Icons.info_outline, title: 'Acerca de'),
        ],
      ),
    );
  }
}
