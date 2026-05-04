import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AuthService adalah lapisan abstraksi antara UI dan Firebase.
/// Kenapa dipisah? Supaya kalau Firebase berubah, kita cukup ubah di sini,
/// tidak perlu ubah di setiap screen.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream user — akan emit setiap kali status login berubah.
  /// Digunakan untuk "auto login": kalau user sudah login sebelumnya,
  /// Firebase akan otomatis mengembalikan session-nya.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User yang sedang login saat ini (bisa null kalau belum login)
  User? get currentUser => _auth.currentUser;

  /// REGISTER: Membuat akun baru dengan email & password
  /// Setelah register, langsung kirim email verifikasi
  /// Juga simpan data tambahan (nama, NIM) ke Firestore karena
  /// Firebase Auth tidak menyimpan data custom
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String nim,
  }) async {
    // Buat akun di Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name di Firebase Auth profile
    await credential.user?.updateDisplayName(name);

    // Simpan data tambahan ke Firestore
    // Kenapa Firestore? Karena Firebase Auth hanya menyimpan:
    // email, password, displayName, photoURL — tidak bisa tambah field custom
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'nim': nim,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'profileImagePath': '', // default kosong
    });

    // Kirim email verifikasi ke email yang baru didaftarkan
    await credential.user?.sendEmailVerification();

    return credential;
  }

  /// SIGN IN: Login dengan email & password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// SIGN OUT: Logout dari Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// FORGOT PASSWORD: Kirim link reset password ke email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// SEND EMAIL VERIFICATION: Kirim ulang email verifikasi
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// RELOAD USER: Refresh status user dari server Firebase
  /// Penting untuk cek apakah email sudah diverifikasi,
  /// karena status lokal tidak otomatis update
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Cek apakah email user sudah diverifikasi
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Ambil data user dari Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Update profile image path di Firestore
  Future<void> updateProfileImage(String imagePath) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'profileImagePath': imagePath,
    });
  }
}