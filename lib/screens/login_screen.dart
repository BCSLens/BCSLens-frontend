// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      AppLogger.log('❌ Login validation failed: Empty fields');
      setState(() {
        _errorMessage = 'Please enter both email and password';
        _isLoading = false;
      });
      return;
    }
    
    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      AppLogger.log('❌ Login validation failed: Invalid email format');
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }
    
    // Validate password length
    if (password.length < 8) {
      AppLogger.log('❌ Login validation failed: Password too short');
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
        _isLoading = false;
      });
      return;
    }
    
    try {
      AppLogger.log('🔐 Login attempt: email=${email.substring(0, email.indexOf('@'))}@***');
      final authService = AuthService();
      final success = await authService.signIn(email, password);
      
      if (success) {
        AppLogger.log('✅ Login successful: userId=${authService.userId}');
        // Navigate to records screen
        Navigator.pushReplacementNamed(context, "/records");
      } else {
        AppLogger.log('❌ Login failed: Invalid credentials');
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      AppLogger.log('❌ Login error: ${e.toString()}');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGoogleLogin() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      AppLogger.log('🔐 Google login attempt');
      final authService = AuthService();
      final success = await authService.signInWithGoogle();
      
      if (success) {
        AppLogger.log('✅ Google login successful: userId=${authService.userId}');
        // Navigate to records screen
        Navigator.pushReplacementNamed(context, "/records");
      } else {
        AppLogger.log('❌ Google login failed: User cancelled or error');
        setState(() {
          _errorMessage = 'Google login failed. Please try again.';
        });
      }
    } catch (e) {
      String errorMsg = 'Google login failed. Please try again.';
      
      // More user-friendly error messages
      if (e.toString().contains('12500')) {
        errorMsg = 'Sign-in was cancelled or failed. Please try again.';
        AppLogger.log('❌ Google login error: User cancelled (12500)');
      } else if (e.toString().contains('DEVELOPER_ERROR') || e.toString().contains('10:')) {
        errorMsg = 'Configuration error. Please contact support.';
        AppLogger.log('❌ Google login error: Configuration error (10)');
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMsg = 'Network error. Please check your internet connection.';
        AppLogger.log('❌ Google login error: Network error');
      } else {
        AppLogger.log('❌ Google login error: ${e.toString()}');
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space from top to logo: 176px
                SizedBox(height: 176),

                // Logo (centered)
                Center(
                  child: Image.asset(
                    'assets/images/bcs_lens_logo.png',
                    width: 198,
                    height: 53,
                  ),
                ),

                // Space to ensure "Login to your account" is at 261px from top
                SizedBox(height: 40),

                // "Login to your account" text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Login to your account',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
                  ),
                ),
                
                // Error message if any
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                
                // Space to ensure email field is at 299px from top
                SizedBox(height: 22),

                // Email field - with lighter background and rounded corners
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Password field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                // Forgot Password with proper color
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(color: Color(0xFF6B85C9), fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Login Button with proper blue color and rounded corners
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B85C9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Log In', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 20),
                // Or login with
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'or login with',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  ),
                ),

                const SizedBox(height: 20),

                // Social buttons - Google login only
                Center(
                  child: _socialLoginButton(
                      icon: FontAwesomeIcons.google,
                      color: Colors.red,
                    onTap: _handleGoogleLogin,
                    ),
                ),

                const SizedBox(height: 30),

                // Don't have an account text and Sign Up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF6B85C9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
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

  Widget _socialLoginButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Center(child: FaIcon(icon, color: color, size: 20)),
      ),
    );
  }
}
