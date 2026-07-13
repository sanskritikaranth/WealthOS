import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State pipeline managing the system UI brightness setting
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // Defaults to your gorgeous cyber dark theme

  /// Inverts the current visual brightness state
  void toggleTheme() {
    state = (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
  }
}

/// Global provider giving every element in our 5-tab stack theme awareness
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);