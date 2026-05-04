import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// AboutScreen menampilkan informasi tentang aplikasi.
/// Fitur utama: toggle Dark/Light Mode menggunakan ThemeProvider.
///
/// Kenapa pakai Provider di sini?
/// ThemeProvider adalah "global state" — perubahan tema harus
/// berdampak ke SELURUH app, bukan hanya screen ini.
/// Provider memungkinkan kita akses dan ubah state global itu
/// dari mana saja tanpa perlu passing parameter antar widget.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // context.watch → rebuild widget ini setiap kali ThemeProvider berubah
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── LOGO APLIKASI ─────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 52,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'QuizFirebase',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),

            // ── TOGGLE TEMA ───────────────────────────────────────
            // Ini adalah fitur utama di halaman About sesuai spesifikasi
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Icon yang berubah sesuai tema aktif
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        key: ValueKey(themeProvider.isDarkMode),
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tema Aplikasi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            // Label berubah sesuai tema yang aktif
                            themeProvider.isDarkMode
                                ? 'Mode Gelap aktif'
                                : 'Mode Terang aktif',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Switch untuk toggle tema
                    // Ketika diubah, ThemeProvider akan:
                    // 1. Ganti themeMode
                    // 2. Simpan ke SharedPreferences
                    // 3. Trigger notifyListeners() → semua widget rebuild
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      thumbIcon: WidgetStateProperty.resolveWith(
                        (states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(Icons.dark_mode,
                                size: 14, color: Colors.white);
                          }
                          return const Icon(Icons.light_mode,
                              size: 14, color: Colors.white);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── INFO APLIKASI ─────────────────────────────────────
            _sectionCard(
              context: context,
              title: 'Tentang Aplikasi',
              icon: Icons.info_outlined,
              content:
                  'QuizFirebase adalah aplikasi autentikasi berbasis Firebase '
                  'yang dibangun menggunakan Flutter. Aplikasi ini mendemonstrasikan '
                  'implementasi Firebase Authentication dengan fitur registrasi, '
                  'login, verifikasi email, dan reset password.',
            ),
            const SizedBox(height: 16),

            // ── TEKNOLOGI YANG DIGUNAKAN ──────────────────────────
            _sectionCard(
              context: context,
              title: 'Teknologi',
              icon: Icons.code,
              children: const [
                _TechItem(
                  icon: Icons.flutter_dash,
                  name: 'Flutter',
                  desc: 'UI Framework',
                ),
                _TechItem(
                  icon: Icons.local_fire_department,
                  name: 'Firebase Auth',
                  desc: 'Autentikasi pengguna',
                ),
                _TechItem(
                  icon: Icons.storage,
                  name: 'Cloud Firestore',
                  desc: 'Database pengguna',
                ),
                _TechItem(
                  icon: Icons.palette_outlined,
                  name: 'Material Design 3',
                  desc: 'Design system',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── FITUR APLIKASI ─────────────────────────────────────
            _sectionCard(
              context: context,
              title: 'Fitur',
              icon: Icons.star_outline,
              children: const [
                _FeatureItem('Registrasi dengan validasi form ketat'),
                _FeatureItem('Login dengan email & password'),
                _FeatureItem('Verifikasi email via Firebase'),
                _FeatureItem('Reset password via email'),
                _FeatureItem('Auto-login (persistent session)'),
                _FeatureItem('Upload foto profil dari galeri'),
                _FeatureItem('Toggle Dark / Light Mode'),
              ],
            ),
            const SizedBox(height: 16),

            // ── DEVELOPER INFO ─────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined,
                        color: colorScheme.primary, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Tugas Mobile Programming',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teknik Informatika',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              '© 2025 QuizFirebase. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Widget helper: card dengan section title + icon
  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? content,
    List<Widget>? children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
            if (children != null) ...children,
          ],
        ),
      ),
    );
  }
}

class _TechItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;

  const _TechItem({
    required this.icon,
    required this.name,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            '— $desc',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}