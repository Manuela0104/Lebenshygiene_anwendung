import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _vorname = '';
  String _nachname = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'vorname': _vorname,
          'nachname': _nachname,
          'email': _email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/goal-selection');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('email-already-in-use')
                  ? 'Diese E-Mail-Adresse wird bereits verwendet.'
                  : 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.',
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFffdde1),
              Color(0xFFee9ca7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 40 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isTablet ? 60 : 40),
                      _buildHeader(isTablet),
                      SizedBox(height: isTablet ? 60 : 40),
                      _buildForm(isTablet),
                      SizedBox(height: isTablet ? 40 : 24),
                      _buildRegisterButton(isTablet),
                      SizedBox(height: isTablet ? 24 : 16),
                      _buildLoginLink(isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFee9ca7).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_rounded,
            size: isTablet ? 60 : 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Text(
          'REGISTRIERUNG',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2d3748),
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'fluffy & Co.',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: const Color(0xFF2d3748).withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isTablet) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            icon: Icons.person_outline,
            hint: 'Vorname',
            onSaved: (value) => _vorname = value ?? '',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Bitte geben Sie Ihren Vornamen ein' : null,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInputField(
            icon: Icons.person_outline,
            hint: 'Nachname',
            onSaved: (value) => _nachname = value ?? '',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Bitte geben Sie Ihren Nachnamen ein' : null,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInputField(
            icon: Icons.email_outlined,
            hint: 'E-Mail',
            keyboardType: TextInputType.emailAddress,
            onSaved: (value) => _email = value ?? '',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
              }
              return null;
            },
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInputField(
            icon: Icons.lock_outline,
            hint: 'Passwort',
            obscureText: _obscurePassword,
            onSaved: (value) => _password = value ?? '',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Bitte geben Sie ein Passwort ein';
              }
              if ((value?.length ?? 0) < 6) {
                return 'Das Passwort muss mindestens 6 Zeichen lang sein';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF2d3748).withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFee9ca7),
            size: isTablet ? 24 : 22,
          ),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF2d3748).withOpacity(0.5),
            fontSize: isTablet ? 16 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 20 : 16,
          ),
        ),
        style: TextStyle(
          color: const Color(0xFF2d3748),
          fontSize: isTablet ? 16 : 14,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildRegisterButton(bool isTablet) {
    return SizedBox(
      height: isTablet ? 60 : 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFee9ca7).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
                    width: isTablet ? 24 : 20,
                    height: isTablet ? 24 : 20,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.app_registration,
                        color: Colors.white,
                        size: isTablet ? 24 : 22,
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Text(
                        'Registrieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Schon ein Konto?',
          style: TextStyle(
            color: const Color(0xFF2d3748),
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFee9ca7),
          ),
          child: Text(
            'Anmelden',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
} 