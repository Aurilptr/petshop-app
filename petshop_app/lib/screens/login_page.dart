// File: lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_page.dart'; 
import 'register_page.dart';
import 'admin/admin_home.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // IP ADDRESS BACKEND
  final String _apiUrl = 'http://127.0.0.1:5000';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  final Color _bgStart = const Color(0xFF0F2027); 
  final Color _bgEnd = const Color(0xFF203A43); 
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal Cyan
  final Color _errorColor = const Color(0xFFEF5350); // Merah lembut (bukan pink)

  Future<void> _loginUser() async {
    print("[LoginPage] Login process started...");
    setState(() => _isLoading = true);

    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password wajib diisi');
      setState(() => _isLoading = false);
      return; 
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print("[LoginPage] Status: ${response.statusCode}");
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final user = responseData['user'];
        final String role = user['role'] ?? 'client'; 

        if (!mounted) return;
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminHomePage(userData: user)));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage(userData: user)));
        }
      } else {
        _showError(responseData['message']);
      }
    } catch (e) {
      print("[LoginPage] Error: $e");
      _showError('Gagal terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgEnd], // Background Navy
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 70, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 15),
                const Text(
                  'PAWMATE',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your Pet, Our Passion',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 1),
                ),
                const SizedBox(height: 50),

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

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _loginUser,
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accentColor, const Color(0xFF2C5364)], // Teal Gradient
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(
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
                    Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      cursorColor: _accentColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), // Background transparan gelap
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _errorColor, width: 2),
        ),
        
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      ),
    );
  }
}