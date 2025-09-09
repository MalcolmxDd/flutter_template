import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/src/bloc/auth_bloc.dart';
import 'package:flutter_template/src/bloc/theme_bloc.dart';
import 'package:flutter_template/src/bloc/theme_event.dart';
import 'package:flutter_template/src/bloc/theme_state.dart';
import 'package:flutter_template/src/bloc/users_bloc.dart';
import 'package:flutter_template/src/bloc/scanner_bloc.dart';
import 'package:flutter_template/src/presentation/pages/auth/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_template/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Needed for async main

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => ThemeBloc()..add(ThemeLoaded())),
        BlocProvider(create: (context) => UsersBloc()),
        BlocProvider(create: (context) => ScannerBloc()),
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
