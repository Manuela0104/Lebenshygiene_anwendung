import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo ou nom de l'app
                  Column(
                    children: const [
                      Icon(Icons.favorite, color: Colors.pink, size: 48),
                      SizedBox(height: 8),
                      Text('LEBENSHYGIENE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
                      SizedBox(height: 4),
                      Text('fluffy & Co.', style: TextStyle(fontSize: 14, color: Colors.pinkAccent)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Champs e-mail
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email, color: Colors.pink),
                      hintText: 'E-Mail',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champs mot de passe
                  TextField(
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
                  // Bouton connexion avec dégradé
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
                      onPressed: _isLoading ? null : _signIn,
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
                              : const Text('Anmelden', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lien Pas encore de compte ?
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Noch kein Konto?', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  // Lien Mot de passe oublié ?
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Passwort vergessen?', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 