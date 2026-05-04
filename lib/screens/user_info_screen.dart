import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'signin_screen.dart';

/// UserInfoScreen menampilkan:
/// 1. Nama mahasiswa dari Firebase Auth (displayName)
/// 2. Status verifikasi email
/// 3. Tombol Verify Email
/// 4. Tombol Sign Out
///
/// Konsep penting: email verification di Firebase bersifat ASYNC.
/// Artinya, kalau user baru saja klik link verifikasi di email,
/// app tidak otomatis tahu. Kita harus RELOAD user dari server
/// Firebase dulu untuk mendapatkan status terbaru.
class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _authService = AuthService();
  bool _isCheckingVerification = false;
  bool _isSendingVerification = false;
  bool _isSigningOut = false;

  // Data user dari Firestore
  Map<String, dynamic>? _userData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoadingData = false;
      });
    }
  }

  /// Cek status verifikasi email terkini dari server Firebase.
  /// PENTING: Kita WAJIB reload user dulu sebelum cek.
  /// Kenapa? Karena FirebaseAuth menyimpan data user secara lokal (cache).
  /// Kalau tidak reload, kita hanya baca cache lama → hasilnya tidak akurat.
  Future<void> _checkVerificationStatus() async {
    setState(() => _isCheckingVerification = true);

    try {
      // Reload memaksa Firebase mengambil data user terbaru dari server
      await _authService.reloadUser();

      if (!mounted) return;
      setState(() {}); // Trigger rebuild untuk update tampilan
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memeriksa status verifikasi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingVerification = false);
    }
  }

  /// Kirim ulang email verifikasi
  Future<void> _sendVerificationEmail() async {
    setState(() => _isSendingVerification = true);

    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verifikasi sudah dikirim! Cek inbox kamu.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim email verifikasi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _signOut() async {
    // Tampilkan dialog konfirmasi sebelum sign out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false, // Hapus semua route sebelumnya
      );
    } catch (e) {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final isVerified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Akun'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KARTU INFO USER ──────────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar inisial
                          Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                // Ambil huruf pertama dari nama
                                (_userData?['name'] ?? user?.displayName ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _infoRow(
                            icon: Icons.person,
                            label: 'Nama Mahasiswa',
                            value: _userData?['name'] ??
                                user?.displayName ??
                                'Tidak diketahui',
                          ),
                          const Divider(height: 24),
                          _infoRow(
                            icon: Icons.badge,
                            label: 'NIM',
                            value: _userData?['nim'] ?? '-',
                          ),
                          const Divider(height: 24),
                          _infoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: user?.email ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── STATUS VERIFIKASI EMAIL ───────────────────────
                  Card(
                    elevation: 0,
                    color: isVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isVerified
                            ? Colors.green.withOpacity(0.4)
                            : Colors.orange.withOpacity(0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isVerified
                                    ? Icons.verified
                                    : Icons.warning_amber_rounded,
                                color: isVerified
                                    ? Colors.green
                                    : Colors.orange,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Status Verifikasi Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── KONDISI 1 & 2 sesuai spesifikasi ────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isVerified
                                  ? '✅ Email is verified'    // Kondisi 2
                                  : '⚠️ Email is not verified', // Kondisi 1
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol cek status verifikasi
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isCheckingVerification
                                  ? null
                                  : _checkVerificationStatus,
                              icon: _isCheckingVerification
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              label: const Text('Verify Email'),
                            ),
                          ),

                          // Tombol kirim ulang verifikasi (hanya tampil kalau belum terverifikasi)
                          if (!isVerified) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isSendingVerification
                                    ? null
                                    : _sendVerificationEmail,
                                child: _isSendingVerification
                                    ? const Text('Mengirim...')
                                    : const Text('Kirim Ulang Email Verifikasi'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── TOMBOL SIGN OUT ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSigningOut ? null : _signOut,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Widget helper untuk baris informasi user
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}