import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/users_bloc.dart';

class ActivityData {
  final String day;
  final double value;
  final String tooltip;

  ActivityData(this.day, this.value, this.tooltip);
}

class UserMetricsData {
  final String category;
  final double value;
  final String tooltip;
  final Color color;

  UserMetricsData(this.category, this.value, this.tooltip, this.color);
}

class WeeklyActivityChart extends StatefulWidget {
  final bool isAdmin;

  const WeeklyActivityChart({super.key, this.isAdmin = false});

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<ActivityData> weeklyData = [
    ActivityData('L', 15, 'Completaste 15 tareas el Lunes'),
    ActivityData('M', 22, 'Récord del día: 22 tareas completadas'),
    ActivityData('X', 18, '18 actividades registradas'),
    ActivityData('J', 25, '¡Excelente Jueves! 25 tareas'),
    ActivityData('V', 20, '20 tareas completadas el Viernes'),
    ActivityData('S', 12, 'Fin de semana: 12 actividades'),
    ActivityData('D', 8, 'Domingo tranquilo: 8 tareas'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();

    // Si es admin, cargar estadísticas de usuarios
    if (widget.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UsersBloc>().add(LoadUserStats());
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final gridColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? 'Métricas de Usuarios' : 'Actividad Semanal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.isAdmin)
              BlocBuilder<UsersBloc, UsersState>(
                builder: (context, state) {
                  if (state is UserStatsLoaded) {
                    return Text(
                      'Total: ${state.totalUsers} usuarios registrados',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    );
                  } else if (state is UsersLoading) {
                    return Text(
                      'Cargando métricas...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    );
                  } else {
                    return Text(
                      'Total: 0 usuarios',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    );
                  }
                },
              )
            else
              Text(
                'Total: ${weeklyData.fold(0.0, (sum, item) => sum + item.value).round()} tareas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: widget.isAdmin
                  ? _buildUserMetricsChart(theme, textColor, gridColor)
                  : _buildWeeklyActivityChart(theme, textColor, gridColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMetricsChart(
    ThemeData theme,
    Color textColor,
    Color gridColor,
  ) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is UserStatsLoaded) {
          final userMetrics = [
            UserMetricsData(
              'Total',
              state.totalUsers.toDouble(),
              'Total de usuarios: ${state.totalUsers}',
              Colors.blue,
            ),
            UserMetricsData(
              'Admins',
              state.adminUsers.toDouble(),
              'Administradores: ${state.adminUsers}',
              Colors.red,
            ),
            UserMetricsData(
              'Usuarios',
              state.regularUsers.toDouble(),
              'Usuarios regulares: ${state.regularUsers}',
              Colors.green,
            ),
          ];

          return BarChart(
            BarChartData(
              maxY:
                  (userMetrics
                              .map((e) => e.value)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2)
                      .ceil()
                      .toDouble(),
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    userMetrics
                            .map((e) => e.value)
                            .reduce((a, b) => a > b ? a : b) >
                        10
                    ? 5
                    : 1,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: gridColor.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      );
                    },
                    interval:
                        userMetrics
                                .map((e) => e.value)
                                .reduce((a, b) => a > b ? a : b) >
                            10
                        ? 5
                        : 1,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= userMetrics.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        userMetrics[value.toInt()].category,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      userMetrics[group.x.toInt()].tooltip,
                      TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  if (response == null || response.spot == null) {
                    setState(() => touchedIndex = -1);
                    return;
                  }
                  setState(
                    () => touchedIndex = response.spot!.touchedBarGroupIndex,
                  );
                },
              ),
              barGroups: userMetrics.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.value * _animation.value,
                      color: data.color,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY:
                            userMetrics
                                .map((e) => e.value)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2,
                        color: gridColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  showingTooltipIndicators: touchedIndex == index ? [0] : [],
                );
              }).toList(),
            ),
          );
        } else if (state is UsersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay datos disponibles',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildWeeklyActivityChart(
    ThemeData theme,
    Color textColor,
    Color gridColor,
  ) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return BarChart(
      BarChartData(
        maxY: 30,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: gridColor.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 12,
                  ),
                );
              },
              interval: 10,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= weeklyData.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  weeklyData[value.toInt()].day,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                weeklyData[group.x.toInt()].tooltip,
                TextStyle(color: textColor, fontWeight: FontWeight.w500),
              );
            },
          ),
          touchCallback: (event, response) {
            if (response == null || response.spot == null) {
              setState(() => touchedIndex = -1);
              return;
            }
            setState(() => touchedIndex = response.spot!.touchedBarGroupIndex);
          },
        ),
        barGroups: weeklyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final barGradient = LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          );
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value * _animation.value,
                gradient: barGradient,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 30,
                  color: gridColor.withOpacity(0.1),
                ),
              ),
            ],
            showingTooltipIndicators: touchedIndex == index ? [0] : [],
          );
        }).toList(),
      ),
    );
  }
}
