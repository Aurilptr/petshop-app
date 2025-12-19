// File: lib/screens/register_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final String _apiUrl = 'http://127.0.0.1:5000';

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  // --- PALET WARNA ELEGANT MIDNIGHT (Sama dengan Login Page) ---
  final Color _bgStart = const Color(0xFF0F2027); 
  final Color _bgEnd = const Color(0xFF203A43); 
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal Cyan
  final Color _errorColor = const Color(0xFFEF5350); 

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  Future<void> _registerUser() async {
    print("[RegisterPage] Register button clicked.");
    setState(() => _isLoading = true);

    final String nama = _namaController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (nama.isEmpty || email.isEmpty || password.isEmpty) {
      print("[RegisterPage] Validation failed: Empty fields.");
      _showStatus('Semua field wajib diisi!', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      print("[RegisterPage] Sending POST request to $_apiUrl/api/users/register");
      
      final response = await http.post(
        Uri.parse('$_apiUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_lengkap': nama,
          'email': email,
          'password': password,
        }),
      );

      print("[RegisterPage] Response Status: ${response.statusCode}");
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        print("[RegisterPage] Registration Successful.");
        _showStatus('Registrasi berhasil! Silakan login.', isError: false);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context); 
        });
      } else {
        print("[RegisterPage] Registration Failed: ${responseData['message']}");
        _showStatus(responseData['message'], isError: true);
      }
    } catch (e) {
      print('[RegisterPage] Error: $e');
      _showStatus('Tidak dapat terhubung ke server.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatus(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: _fontFamily, color: Colors.white)),
        backgroundColor: isError ? _errorColor : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient Full Screen
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back Button Custom
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 20),
                Icon(Icons.person_add_alt_1, size: 70, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 15),
                
                Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gabung dengan komunitas PawMate',
                  style: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: Colors.white70),
                ),
                
                const SizedBox(height: 40),

                // --- INPUT NAMA ---
                _buildFixedInput(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  isPassword: false,
                ),
                const SizedBox(height: 20),

                // --- INPUT EMAIL ---
                _buildFixedInput(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  isPassword: false,
                ),
                const SizedBox(height: 20),

                // --- INPUT PASSWORD ---
                _buildFixedInput(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                
                const SizedBox(height: 40),

                // --- TOMBOL REGISTER (Gradient Style) ---
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _registerUser,
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accentColor, const Color(0xFF2C5364)], 
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'DAFTAR SEKARANG',
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white, 
                                  letterSpacing: 1.5
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Sudah punya akun? ", style: TextStyle(fontFamily: _fontFamily, color: Colors.white70)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login disini',
                        style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET INPUT KHUSUS (Copy dari Login Page agar Border tidak Pink) ---
  Widget _buildFixedInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
      cursorColor: _accentColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), // Background transparan gelap
        
        // Border Biasa
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        
        // Border Fokus (Teal)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      ),
    );
  }
}