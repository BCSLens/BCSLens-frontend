// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  String _selectedRole = 'pet-owner';
  bool _isLoading = false;
  String? _errorMessage;
  bool _privacyConsentAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim();
    final firstname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate required fields
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty ||
        firstname.isEmpty ||
        lastname.isEmpty) {
      print('❌ Signup validation failed: Empty required fields');
      setState(() {
        _errorMessage = 'Please fill all required fields';
        _isLoading = false;
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      print('❌ Signup validation failed: Invalid email format');
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    // Validate password length
    if (password.length < 8) {
      print('❌ Signup validation failed: Password too short');
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long';
        _isLoading = false;
      });
      return;
    }

    // Validate password contains letters and numbers
    if (!password.contains(RegExp(r'[A-Za-z]'))) {
      print('❌ Signup validation failed: Password must contain letters');
      setState(() {
        _errorMessage = 'Password must contain at least one letter';
        _isLoading = false;
      });
      return;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      print('❌ Signup validation failed: Password must contain numbers');
      setState(() {
        _errorMessage = 'Password must contain at least one number';
        _isLoading = false;
      });
      return;
    }

    // Validate password match
    if (password != confirmPassword) {
      print('❌ Signup validation failed: Passwords do not match');
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    // Validate username (alphanumeric, underscore, hyphen, 3-20 chars)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]{3,20}$');
    if (!usernameRegex.hasMatch(username)) {
      print('❌ Signup validation failed: Invalid username format');
      setState(() {
        _errorMessage = 'Username must be 3-20 characters and contain only letters, numbers, underscore, or hyphen';
        _isLoading = false;
      });
      return;
    }

    // Validate name (letters and spaces only, 2-50 chars)
    final nameRegex = RegExp(r'^[a-zA-Z\s]{2,50}$');
    if (!nameRegex.hasMatch(firstname)) {
      print('❌ Signup validation failed: Invalid first name format');
      setState(() {
        _errorMessage = 'First name must be 2-50 characters and contain only letters';
        _isLoading = false;
      });
      return;
    }

    if (!nameRegex.hasMatch(lastname)) {
      print('❌ Signup validation failed: Invalid last name format');
      setState(() {
        _errorMessage = 'Last name must be 2-50 characters and contain only letters';
        _isLoading = false;
      });
      return;
    }

    // Validate phone (optional, but if provided, must be valid format)
    if (phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^[0-9+\-\s()]{8,15}$');
      if (!phoneRegex.hasMatch(phone)) {
        print('❌ Signup validation failed: Invalid phone format');
        setState(() {
          _errorMessage = 'Please enter a valid phone number (8-15 digits)';
          _isLoading = false;
        });
        return;
      }
    }

    // Validate privacy consent
    if (!_privacyConsentAccepted) {
      print('❌ Signup validation failed: Privacy consent not accepted');
      setState(() {
        _errorMessage = 'Please accept the Privacy Policy to continue';
        _isLoading = false;
      });
      return;
    }

    try {
      print('🔐 Signup attempt: email=${email.substring(0, email.indexOf('@'))}@***, username=$username, role=$_selectedRole');
      // Sign up
      final authService = AuthService();
      final result = await authService.signUp(
        email,
        password,
        confirmPassword,
        username,
        firstname,
        lastname,
        phone,
        _selectedRole,
        _privacyConsentAccepted,
      );

      print('📝 Signup result: success=${result['success']}');
      
      if (result['success'] == true) {
        print('✅ Signup successful: userId=${authService.userId}');
        // Navigate to records screen
        Navigator.pushReplacementNamed(context, "/records");
      } else {
        final errorMsg = result['message'] ?? 'Failed to create account. Please try again.';
        print('❌ Signup failed: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Signup exception: ${e.toString()}');
      print('   Stack trace: ${stackTrace.toString().substring(0, stackTrace.toString().length > 200 ? 200 : stackTrace.toString().length)}...');
      setState(() {
        _errorMessage = 'Error: $e';
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
                // Space from top to logo: 176px (same as login)
                const SizedBox(height: 100),

                // Logo (centered)
                Center(
                  child: Image.asset(
                    'assets/images/bcs_lens_logo.png',
                    width: 193,
                    height: 53,
                  ),
                ),

                // Space to position "Create your Account" text
                const SizedBox(height: 40),

                // "Create your Account" text - left aligned
                const Text(
                  'Create your Account',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
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

                // Space before email field
                const SizedBox(height: 22),

                // Username field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Username',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // First name field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _firstnameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'First Name',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Last name field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _lastnameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Last Name',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Email field with lighter background and rounded corners
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

                // Confirm Password field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Phone field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Phone',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Role dropdown - styled to match other inputs
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFAAAAAA),
                      ),
                      hintText: 'Role',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFAAAAAA),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'pet-owner',
                        child: Text('Pet Owner'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'expert',
                        child: Text('Expert'),
                      ),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy Consent Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _privacyConsentAccepted,
                      onChanged: (value) {
                        setState(() {
                          _privacyConsentAccepted = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF6B86C9),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'I agree to the ',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      _privacyConsentAccepted = !_privacyConsentAccepted;
                                    });
                                  },
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: Color(0xFF6B86C9),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(
                                      context,
                                      '/privacy-policy',
                                    );
                                  },
                              ),
                              TextSpan(
                                text: ' and consent to the collection and use of my personal data.',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      _privacyConsentAccepted = !_privacyConsentAccepted;
                                    });
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B86C9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFF6B85C9),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
