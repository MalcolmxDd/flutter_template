import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/auth_bloc.dart';
import 'package:flutter_template/src/bloc/theme_bloc.dart';
import 'package:flutter_template/src/bloc/theme_event.dart';
import 'package:flutter_template/src/bloc/theme_state.dart';
import 'package:flutter_template/src/bloc/users_bloc.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';
import 'package:flutter_template/src/data/database_helper.dart';
import 'package:flutter_template/src/presentation/pages/splash/splash_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Needed for async main
  // Initialize FFI for sqflite on desktop platforms, but not on web.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Crear usuario admin si no existe
  final databaseHelper = DatabaseHelper();
  await databaseHelper.createAdminUserIfNotExists();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(DatabaseHelper())),
        BlocProvider(create: (context) => ThemeBloc()..add(ThemeLoaded())),
        BlocProvider(create: (context) => UsersBloc(DatabaseHelper())),
        BlocProvider(create: (context) => ScannerBloc(DatabaseHelper())),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Flutter Template',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: state.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
