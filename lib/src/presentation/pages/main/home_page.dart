import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_template/src/bloc/auth_bloc.dart';
import 'package:flutter_template/src/presentation/pages/auth/login_page.dart';
import 'package:flutter_template/src/presentation/pages/main/dashboard_page.dart';
import 'package:flutter_template/src/presentation/pages/user/profile_page.dart';
import 'package:flutter_template/src/presentation/pages/settings/settings_page.dart';
import 'package:flutter_template/src/presentation/pages/user/users_management_page.dart';
import 'package:flutter_template/src/presentation/pages/scanner/scanner_page.dart';
import 'package:flutter_template/src/presentation/pages/scanner/codes_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Simplified navigation items for static UI parts
  final List<Map<String, dynamic>> _navigationItems = [
    {
      'icon': Icons.dashboard_outlined,
      'text': 'Dashboard',
      'requiredPermission': null,
    },
    {
      'icon': Icons.qr_code_scanner,
      'text': 'Escanear',
      'requiredPermission': null,
    },
    {'icon': Icons.history, 'text': 'Historial', 'requiredPermission': null},
    {
      'icon': Icons.person_outline,
      'text': 'Perfil',
      'requiredPermission': null,
    },
    {
      'icon': Icons.people_outline,
      'text': 'Usuarios',
      'requiredPermission': 'admin',
    },
    {
      'icon': Icons.settings_outlined,
      'text': 'Configuración',
      'requiredPermission': null,
    },
  ];

  bool _hasPermission(List<String> userRoles, String? requiredPermission) {
    if (requiredPermission == null) {
      return true; // No specific permission required
    }
    return userRoles.contains(requiredPermission);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_navigationItems[_selectedIndex]['text']),
          backgroundColor: theme.primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmationDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              final List<String> userRoles = state.roles;

              final List<Widget> allPages = [
                DashboardPage(
                  username: state.username,
                  userRoles: userRoles,
                  onNavigateToPage: _onItemTapped, // Pasar el callback
                ),
                const ScannerPage(),
                const CodesHistoryPage(),
                ProfilePage(username: state.username, userRoles: userRoles),
                const UsersManagementPage(),
                SettingsPage(userRoles: userRoles),
              ];

              // Removed unused availableNavigationItems variable

              final List<Widget> availablePages = [];
              for (int i = 0; i < _navigationItems.length; i++) {
                if (_hasPermission(
                  userRoles,
                  _navigationItems[i]['requiredPermission'],
                )) {
                  availablePages.add(allPages[i]);
                }
              }

              // Adjust selected index if the current one is no longer available
              if (_selectedIndex >= availablePages.length) {
                _selectedIndex = 0;
              }

              return Scaffold(
                drawer: _buildDrawer(theme, userRoles),
                bottomNavigationBar: _buildBottomNavBar(theme, userRoles),
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: availablePages[_selectedIndex],
                  ),
                ),
              );
            }
            // Show a loader while the state is not AuthSuccess (e.g., during logout transition)
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Cerrar Sesión'),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutButtonPressed());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(ThemeData theme, List<String> userRoles) {
    final List<Map<String, dynamic>> availableNavigationItems = _navigationItems
        .where((item) => _hasPermission(userRoles, item['requiredPermission']))
        .toList();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: const Text(
              'Menú',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          for (int i = 0; i < availableNavigationItems.length; i++)
            ListTile(
              leading: Icon(availableNavigationItems[i]['icon']),
              title: Text(availableNavigationItems[i]['text']),
              selected: _selectedIndex == i,
              onTap: () {
                _onItemTapped(i);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme, List<String> userRoles) {
    final List<Map<String, dynamic>> availableNavigationItems = _navigationItems
        .where((item) => _hasPermission(userRoles, item['requiredPermission']))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: 4,
            activeColor: Colors.white,
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.primaryColor,
            color: Colors.black,
            tabs: [
              for (final item in availableNavigationItems)
                GButton(
                  icon: item['icon'],
                  text: item['text'],
                  textStyle: const TextStyle(fontSize: 10),
                ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
