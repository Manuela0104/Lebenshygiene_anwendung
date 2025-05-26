import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8EAF6), Color(0xFFFFD6C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Column(
                      children: const [
                        Icon(Icons.person_add, color: Colors.pink, size: 48),
                        SizedBox(height: 8),
                        Text('REGISTRIERUNG', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
                        SizedBox(height: 4),
                        Text('fluffy & Co.', style: TextStyle(fontSize: 14, color: Colors.pinkAccent)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: Colors.pink),
                        hintText: 'Vorname',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Vorname erforderlich' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: Colors.pink),
                        hintText: 'Nachname',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Nachname erforderlich' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.pink),
                        hintText: 'E-Mail',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty ? 'E-Mail erforderlich' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.pink),
                        hintText: 'Passwort',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.pinkAccent),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Mindestens 6 Zeichen' : null,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: _isLoading ? null : _register,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFFFD6C0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white),
                                  )
                                : const Text('Registrieren', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Schon ein Konto? Anmelden', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 