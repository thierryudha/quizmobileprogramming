import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider bertanggung jawab menyimpan dan mengubah tema aplikasi.
/// Menggunakan ChangeNotifier agar widget yang listen bisa rebuild otomatis.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(bool isDark)
      : _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggle antara dark dan light mode, lalu simpan ke SharedPreferences
  /// supaya pilihan user tetap tersimpan walau app ditutup
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    // Simpan preference ke local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);

    // Beritahu semua widget yang listen untuk rebuild
    notifyListeners();
  }
}