import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      );

  ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      );

  ThemeData getTheme() {
    return isDarkMode ? darkTheme : lightTheme;
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
