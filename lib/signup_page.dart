import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPass = false, _showConfirm = false, _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ---------- Logic (unchanged) ----------
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification();
        await FirebaseFirestore.instance
            .collection('loginData')
            .doc(user.uid)
            .set({
              'email': user.email,
              'password': _pass.text.trim(), // kept as in your original
              'createdAt': Timestamp.now(),
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your Gmail.'),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------- UI helpers ----------
  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.55),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    bool password = false,
    bool visible = false,
    VoidCallback? toggle,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade800.withOpacity(0.85),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon:
          password
              ? IconButton(
                icon: Icon(
                  visible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: toggle,
              )
              : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _input({
    required TextEditingController c,
    required String hint,
    required IconData icon,
    bool password = false,
    bool visible = false,
    VoidCallback? toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: password && !visible,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(
        hint: hint,
        icon: icon,
        password: password,
        visible: visible,
        toggle: toggle,
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
        ? null
        : 'Please enter a valid email';
  }

  String? _passValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password';
    return v.length < 6 ? 'Password must be at least 6 characters' : null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    return v != _pass.text ? 'Passwords do not match' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // exact same background as login
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF111827)],
              ),
            ),
          ),
          _blob(top: -60, left: -40, size: 220, color: const Color(0xFF81D4FA)),
          _blob(
            bottom: -50,
            right: -30,
            size: 200,
            color: const Color(0xFFA5D6A7),
          ),
          _blob(
            top: 140,
            right: -60,
            size: 160,
            color: const Color(0xFFFFF59D),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                  title: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _input(
                            c: _email,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 16),
                          _input(
                            c: _pass,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            password: true,
                            visible: _showPass,
                            toggle:
                                () => setState(() => _showPass = !_showPass),
                            validator: _passValidator,
                          ),
                          const SizedBox(height: 16),
                          _input(
                            c: _confirm,
                            hint: 'Confirm Password',
                            icon: Icons.lock_reset_outlined,
                            password: true,
                            visible: _showConfirm,
                            toggle:
                                () => setState(
                                  () => _showConfirm = !_showConfirm,
                                ),
                            validator: _confirmValidator,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF69B7FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _loading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Already have an account? Log in',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
