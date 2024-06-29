// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_app/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('should toggle theme correctly', () {
      final themeProvider = ThemeProvider();

      expect(themeProvider.isDarkMode, isFalse);

      themeProvider.toggleTheme(true);
      expect(themeProvider.isDarkMode, isTrue);

      themeProvider.toggleTheme(false);
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('should return correct theme data', () {
      final themeProvider = ThemeProvider();

      expect(themeProvider.getTheme(), themeProvider.lightTheme);

      themeProvider.toggleTheme(true);
      expect(themeProvider.getTheme(), themeProvider.darkTheme);
    });
  });
}
