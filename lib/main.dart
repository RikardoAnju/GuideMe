import 'package:flutter/material.dart';
import 'package:guide_me/Splasscreen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Memuat file .env dan menampilkan error jika gagal
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint('✅ File .env berhasil dimuat.');
  } catch (e) {
    debugPrint('❌ Gagal memuat file .env: $e');
  }

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      ),
    );
    debugPrint('✅ Firebase berhasil diinisialisasi.');
  } catch (e) {
    debugPrint('❌ Error saat inisialisasi Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// Fungsi untuk mendapatkan API Key Brevo dari .env
String getBrevoApiKey() {
  final apiKey = dotenv.env['SENDINBLUE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    debugPrint('❌ API Key Brevo tidak ditemukan di .env');
  }
  return apiKey ?? '';
}