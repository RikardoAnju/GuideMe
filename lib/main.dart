import 'package:flutter/material.dart';
import 'Splasscreen.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  //await dotenv.load(fileName: "assets/.env");

  //try {
    //await Firebase.initializeApp(
      //options: FirebaseOptions(
        //apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        //appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        //messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        //projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        //storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      //),
    //);
    //print('✅ Firebase initialized successfully.');
  //} catch (e) {
  //  print('❌ Error initializing Firebase: $e');
  //}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

 @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  SplashScreen(),
    ); 
  }
}

// Fungsi untuk menggunakan API Key Brevo dari .env
//String getBrevoApiKey() {
  //final apiKey = dotenv.env['SENDINBLUE_API_KEY'];
  //if (apiKey == null || apiKey.isEmpty) {
    //print('❌ API Key Brevo tidak ditemukan di .env');
  //}
  //return apiKey ?? '';
//}
