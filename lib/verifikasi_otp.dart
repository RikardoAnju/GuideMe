import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:guide_me/Resetpassword.dart';
import 'package:guide_me/services/email_service.dart';

class VerifikasiOtp extends StatefulWidget {
  final String email;
  final String otp;
  final String userId;
  final String? temporaryResetToken;
  final String resetToken;

  const VerifikasiOtp({
    super.key,
    required this.email,
    required this.userId,
    this.otp = '',
    this.temporaryResetToken,
    required this.resetToken,
  });

  @override
  State<VerifikasiOtp> createState() => VerifikasiOtpState();
}

class VerifikasiOtpState extends State<VerifikasiOtp> {
  final TextEditingController _otpController = TextEditingController();
  late String _generatedOtp;
  int _remainingSeconds = 300;
  Timer? _timer;
  bool _isOtpExpired = false;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _generatedOtp = widget.otp;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isOtpExpired = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _formatTimeRemaining() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Peringatan!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showMessage('Masukkan kode OTP terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (!userDoc.exists) {
        _showWarningDialog('Akun tidak ditemukan.');
        return;
      }

      final data = userDoc.data()!;
      final storedOtp = data['otp'] ?? '';
      final expiresAtStr = data['expiresAt'] ?? '';
      final expiresAt = DateTime.tryParse(expiresAtStr) ?? DateTime.now().subtract(const Duration(minutes: 1));

      if (DateTime.now().isAfter(expiresAt)) {
        _showWarningDialog('Kode OTP telah kedaluwarsa.');
        return;
      }

      if (_otpController.text == storedOtp) {
        _showMessage('Verifikasi OTP berhasil');

        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'otp': FieldValue.delete(),
          'expiresAt': FieldValue.delete(),
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Resetpassword(
              userId: widget.userId,
              email: widget.email,
              resetToken: widget.resetToken,
            ),
          ),
        );
      } else {
        _showWarningDialog('Kode OTP tidak valid.');
      }
    } catch (e) {
      _showWarningDialog('Terjadi kesalahan saat verifikasi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      final newOtp = _generateSecureOtp();
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'otp': newOtp,
        'expiresAt': expiryTime.toIso8601String(),
      });

      await EmailService.sendOTP(widget.email, newOtp);

      if (!mounted) return;
      setState(() {
        _generatedOtp = newOtp;
        _isOtpExpired = false;
        _remainingSeconds = 300;
        _otpController.clear();
      });

      _startTimer();
      _showMessage('Kode OTP baru telah dikirim ke ${widget.email}');
    } catch (e) {
      if (mounted) _showWarningDialog('Gagal mengirim ulang OTP: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _generateSecureOtp() {
    final int seed = DateTime.now().millisecondsSinceEpoch;
    final int code = (100000 + (seed % 900000));
    return code.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Text(
                      "VERIFIKASI OTP",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Masukkan kode OTP yang dikirim ke",
                              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            PinCodeTextField(
                              appContext: context,
                              length: 6,
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              animationType: AnimationType.fade,
                              autoDisposeControllers: false,
                              enableActiveFill: true,
                              onChanged: (_) {},
                              onCompleted: (_) {
                                if (!_isOtpExpired && !_isLoading) _verifyOtp();
                              },
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(8),
                                fieldHeight: 55,
                                fieldWidth: 45,
                                activeFillColor: isDarkMode ? Colors.grey[700] : Colors.white,
                                inactiveFillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                                selectedFillColor: isDarkMode ? Colors.grey[600] : Colors.grey[200],
                                activeColor: primaryColor,
                                inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                selectedColor: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: (_isOtpExpired ? Colors.red : primaryColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                _isOtpExpired
                                    ? "Kode OTP telah kedaluwarsa"
                                    : "Berlaku: ${_formatTimeRemaining()}",
                                style: TextStyle(
                                  color: _isOtpExpired ? Colors.red : primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: (_isOtpExpired || _isLoading) ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text("VERIFIKASI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton.icon(
                              onPressed: (_isResending || !_isOtpExpired) ? null : _resendOtp,
                              icon: _isResending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
                                  : Icon(Icons.refresh, size: 16, color: _isOtpExpired ? primaryColor : Colors.grey),
                              label: Text(
                                "Kirim Ulang Kode OTP",
                                style: TextStyle(
                                  color: _isOtpExpired ? primaryColor : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
