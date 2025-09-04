import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.light)) {
    on<ThemeLoaded>(_onThemeLoaded);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onThemeLoaded(ThemeLoaded event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    emit(ThemeState(themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', event.isDarkMode);
    emit(ThemeState(themeMode: event.isDarkMode ? ThemeMode.dark : ThemeMode.light));
  }
}
