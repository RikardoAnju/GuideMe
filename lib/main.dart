import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guide_me/Splasscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "mailersend-proxy/.env");

  // Initialize Firebase
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
    print('✅ Firebase initialized successfully.');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

//
// ========== MailerSend Env Helpers ==========
//

/// Mengambil API Key MailerSend dari file .env
String getMailerSendApiKey() {
  final apiKey = dotenv.env['MAILERSEND_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ MAILERSEND_API_KEY tidak ditemukan di .env');
  }
  return apiKey ?? '';
}

/// Mengambil sender email MailerSend dari file .env
String getMailerSendSenderEmail() {
  final sender = dotenv.env['MAILERSEND_SENDER_EMAIL'];
  if (sender == null || sender.isEmpty) {
    print('❌ MAILERSEND_SENDER_EMAIL tidak ditemukan di .env');
  }
  return sender ?? '';
}
