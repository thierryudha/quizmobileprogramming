import 'package:flutter/material.dart';
import 'user_info_screen.dart';

/// MainScreen adalah wrapper untuk Bottom Navigation Bar.
/// Ini adalah "shell" yang menampung 3 tab:
/// - Tab 0: UserInfo
/// - Tab 1: Profile
/// - Tab 2: About
///
/// Kenapa pakai IndexedStack dan bukan Navigator.push?
/// IndexedStack mempertahankan state setiap tab — jadi kalau user
/// buka tab About lalu balik ke UserInfo, state UserInfo tidak reset.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar screen untuk setiap tab
  // Dibuat sebagai late final supaya hanya diinisialisasi sekali
  final List<Widget> _screens = const [
    UserInfoScreen(),
    ProfileScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menampilkan screen berdasarkan index,
      // tapi TETAP menyimpan state semua screen di memori
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.info_outlined),
            selectedIcon: Icon(Icons.info),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Tentang',
          ),
        ],
      ),
    );
  }
}