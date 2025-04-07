import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static const String apiUrl = "https://api.brevo.com/v3/smtp/email";
  
  static Future<bool> sendOTP(String recipientEmail, String otp) async {
    final String? apiKey = dotenv.env['SENDINBLUE_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ API Key tidak ditemukan!");
      return false;
    }

    final Map<String, dynamic> emailData = {
      "sender": {"name": "Guideme", "email": "anjo24696@gmail.com"},
      "to": [
        {"email": recipientEmail}
      ],
      "subject": "Kode OTP Anda",
      "textContent": "Kode OTP Anda adalah: $otp\nJangan bagikan kode ini ke siapa pun!",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "api-key": apiKey,
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 201) {
        print("✅ OTP berhasil dikirim ke $recipientEmail");
        return true;
      } else {
        print("❌ Gagal mengirim OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error: $e");
      return false;
    }
  }
}
