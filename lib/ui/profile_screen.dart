import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

/// ProfileScreen menampilkan profil pengguna dan fitur:
/// 1. Upload foto dari galeri (image_picker)
/// 2. Pilih avatar default dari koleksi
/// 3. Tampil info user (nama, email, NIM)
///
/// Konsep penting:
/// - Foto profil disimpan sebagai PATH lokal di Firestore,
///   bukan file-nya sendiri (karena tidak pakai Firebase Storage).
/// - Setiap buka app, path dibaca dari Firestore lalu File dibaca dari disk.
/// - Ini cukup untuk tugas. Untuk production, pakai Firebase Storage.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Path foto yang dipilih user (dari galeri)
  String? _localImagePath;

  // Index avatar default yang dipilih (-1 = tidak pakai avatar default)
  int _selectedAvatarIndex = -1;

  // Daftar warna untuk avatar default
  final List<Map<String, dynamic>> _defaultAvatars = [
    {'color': Colors.indigo, 'icon': Icons.person, 'label': 'Indigo'},
    {'color': Colors.teal, 'icon': Icons.person, 'label': 'Teal'},
    {'color': Colors.deepOrange, 'icon': Icons.person, 'label': 'Orange'},
    {'color': Colors.purple, 'icon': Colors.person, 'label': 'Purple'},
    {'color': Colors.green, 'icon': Icons.person, 'label': 'Green'},
    {'color': Colors.pink, 'icon': Icons.person, 'label': 'Pink'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;

        // Restore state foto dari data yang tersimpan
        final savedPath = data?['profileImagePath'] ?? '';
        if (savedPath.startsWith('avatar:')) {
          // Format simpan avatar default: "avatar:2" (index)
          _selectedAvatarIndex = int.tryParse(savedPath.split(':')[1]) ?? -1;
        } else if (savedPath.isNotEmpty) {
          _localImagePath = savedPath;
        }
      });
    }
  }

  /// Buka galeri dan pilih foto
  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres supaya tidak terlalu besar
        maxWidth: 512,
        maxHeight: 512,
      );

      if (picked == null) return; // User cancel

      setState(() {
        _localImagePath = picked.path;
        _selectedAvatarIndex = -1; // Reset pilihan avatar default
      });

      await _saveProfileImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka galeri.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Pilih avatar default berdasarkan index
  Future<void> _selectDefaultAvatar(int index) async {
    setState(() {
      _selectedAvatarIndex = index;
      _localImagePath = null; // Reset foto dari galeri
    });
    await _saveProfileImage();
  }

  /// Simpan pilihan foto ke Firestore
  Future<void> _saveProfileImage() async {
    setState(() => _isUpdating = true);

    try {
      String pathToSave = '';
      if (_localImagePath != null) {
        pathToSave = _localImagePath!;
      } else if (_selectedAvatarIndex >= 0) {
        pathToSave = 'avatar:$_selectedAvatarIndex';
      }

      await _authService.updateProfileImage(pathToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan foto profil.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Tampilkan bottom sheet pilihan: galeri atau avatar default
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Foto Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Opsi 1: Upload dari galeri
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Upload dari Galeri'),
                  subtitle: const Text('Pilih foto dari penyimpanan HP'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
                const Divider(),

                // Opsi 2: Pilih avatar default
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Atau pilih avatar default:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Grid avatar default
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _defaultAvatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _defaultAvatars[index];
                      final isSelected = _selectedAvatarIndex == index;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _selectDefaultAvatar(index);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: avatar['color'] as Color,
                                child: Icon(
                                  avatar['icon'] as IconData,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              // Tanda centang kalau ini yang dipilih
                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build widget avatar yang tampil di halaman profil
  Widget _buildAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final initial = (_userData?['name'] ?? user?.displayName ?? 'U')
        .substring(0, 1)
        .toUpperCase();

    Widget avatarContent;

    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      // Tampilkan foto dari galeri
      avatarContent = ClipOval(
        child: Image.file(
          File(_localImagePath!),
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        ),
      );
    } else if (_selectedAvatarIndex >= 0 &&
        _selectedAvatarIndex < _defaultAvatars.length) {
      // Tampilkan avatar default
      final avatar = _defaultAvatars[_selectedAvatarIndex];
      avatarContent = CircleAvatar(
        radius: 55,
        backgroundColor: avatar['color'] as Color,
        child: Icon(
          avatar['icon'] as IconData,
          color: Colors.white,
          size: 52,
        ),
      );
    } else {
      // Default: inisial nama
      avatarContent = CircleAvatar(
        radius: 55,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Stack(
      children: [
        avatarContent,
        // Tombol edit di pojok kanan bawah avatar
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Loading indicator saat menyimpan
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── HEADER dengan background warna ──────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar dengan tombol edit
                        _buildAvatar(),
                        const SizedBox(height: 16),

                        // Nama user
                        Text(
                          _userData?['name'] ??
                              user?.displayName ??
                              'Pengguna',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol ganti foto
                        OutlinedButton.icon(
                          onPressed: _showPhotoOptions,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Ganti Foto Profil'),
                        ),
                      ],
                    ),
                  ),

                  // ── DETAIL INFO ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Akun',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              _profileTile(
                                icon: Icons.person_outlined,
                                label: 'Nama Mahasiswa',
                                value: _userData?['name'] ??
                                    user?.displayName ??
                                    '-',
                              ),
                              Divider(
                                  height: 1,
                                  indent: 56,
                                  color: colorScheme.outlineVariant),
                              _profileTile(
                                icon: Icons.badge_outlined,
                                label: 'NIM',
                                value: _userData?['nim'] ?? '-',
                              ),
                              Divider(
                                  height: 1,
                                  indent: 56,
                                  color: colorScheme.outlineVariant),
                              _profileTile(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: user?.email ?? '-',
                              ),
                              Divider(
                                  height: 1,
                                  indent: 56,
                                  color: colorScheme.outlineVariant),
                              _profileTile(
                                icon: user?.emailVerified == true
                                    ? Icons.verified
                                    : Icons.warning_amber_rounded,
                                label: 'Status Email',
                                value: user?.emailVerified == true
                                    ? 'Terverifikasi'
                                    : 'Belum Terverifikasi',
                                valueColor: user?.emailVerified == true
                                    ? Colors.green
                                    : Colors.orange,
                                iconColor: user?.emailVerified == true
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Info pilihan foto saat ini
                        if (_localImagePath != null ||
                            _selectedAvatarIndex >= 0)
                          Card(
                            elevation: 0,
                            color: colorScheme.primaryContainer
                                .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: colorScheme.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    _localImagePath != null
                                        ? 'Menggunakan foto dari galeri'
                                        : 'Menggunakan avatar default #${_selectedAvatarIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? colorScheme.primary,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: valueColor ?? colorScheme.onSurface,
        ),
      ),
    );
  }
}