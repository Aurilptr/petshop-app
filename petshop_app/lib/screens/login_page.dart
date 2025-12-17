// File: lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_page.dart'; // Halaman Client
import 'register_page.dart';
import 'admin/admin_home.dart'; // <--- PENTING: Import Halaman Admin

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // IP KAMU (Pastikan sama dengan API)
  final String _apiUrl = 'http://192.168.101.12:5000';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password tidak boleh kosong!');
      setState(() => _isLoading = false);
      return; 
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final user = responseData['user'];
        final String role = user['role'] ?? 'client'; // Ambil role dari database

        print('Login sukses! User: ${user['nama_lengkap']} ($role)');

        if (!mounted) return;

        // --- LOGIKA PERCABANGAN (ADMIN vs CLIENT) ---
        if (role == 'admin') {
          // JIKA ADMIN -> Masuk Dashboard Admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomePage(userData: user)),
          );
        } else {
          // JIKA CLIENT -> Masuk Toko Biasa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(userData: user)),
          );
        }
        // ---------------------------------------------

      } else {
        _showError(responseData['message']);
      }
    } catch (e) {
      print('Error: $e');
      _showError('Tidak dapat terhubung ke server. Cek IP atau koneksi.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(Icons.pets, size: 100, color: Colors.pink[400]),
              const SizedBox(height: 20),
              const Text(
                'Selamat Datang di PawMate!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              const Text(
                'Silakan login untuk melanjutkan',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink, // Biar tombolnya pink
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text(
                  'Belum punya akun? Daftar di sini',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}