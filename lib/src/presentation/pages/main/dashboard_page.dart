import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/users_bloc.dart';
import 'package:flutter_template/src/presentation/widgets/dashboard_grid.dart';
import 'package:flutter_template/src/presentation/widgets/weekly_activity_chart.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String userRole;
  final Function(int)? onNavigateToPage;

  const DashboardPage({
    super.key,
    required this.username,
    required this.userRole,
    this.onNavigateToPage,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Cargar estadísticas de usuarios si es admin
    if (widget.userRole == 'admin') {
      context.read<UsersBloc>().add(LoadUserStats());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = widget.userRole == 'admin';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Hola, ${widget.username}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin ? 'Panel de Administración' : 'Bienvenido a tu dashboard.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),

          // Estadísticas específicas para admin
          if (isAdmin) ...[_buildAdminStats(), const SizedBox(height: 24)],

          Text(
            'Actividad Semanal',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          WeeklyActivityChart(isAdmin: isAdmin),
          const SizedBox(height: 24),
          Text(
            isAdmin ? 'Gestión del Sistema' : 'Accesos Rápidos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DashboardGrid(
            isAdmin: isAdmin,
            onUsersManagementTap: () {
              // Navegar a la página de usuarios (índice 2)
              if (widget.onNavigateToPage != null) {
                widget.onNavigateToPage!(2);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        // Si no hay estado o es inicial, cargar estadísticas
        if (state is UsersInitial) {
          // Cargar estadísticas automáticamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UsersBloc>().add(LoadUserStats());
          });
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UserStatsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estadísticas de Usuarios',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // En pantallas pequeñas, mostrar en columna
                    return Column(
                      children: [
                        _buildStatCard(
                          'Total Usuarios',
                          state.totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Administradores',
                                state.adminUsers.toString(),
                                Icons.admin_panel_settings,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Usuarios Regulares',
                                state.regularUsers.toString(),
                                Icons.person,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // En pantallas grandes, mostrar en fila
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Usuarios',
                            state.totalUsers.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Administradores',
                            state.adminUsers.toString(),
                            Icons.admin_panel_settings,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Usuarios Regulares',
                            state.regularUsers.toString(),
                            Icons.person,
                            Colors.orange,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          );
        } else if (state is UsersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UsersError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Error al cargar estadísticas: ${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<UsersBloc>().add(LoadUserStats()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
