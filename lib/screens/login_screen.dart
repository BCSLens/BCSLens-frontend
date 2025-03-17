import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                // 261 - 176 - 45 = 40px
                SizedBox(height: 40),

                // "Login to your account" text
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Login to your account',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
                  ),
                ),
                // Space to ensure email field is at 299px from top
                // 299 - 261 - 16 = 22px
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
                // This positioning ensures "Forgot Password" will be at 419px from top
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
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/records");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B85C9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Log In', style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 20),
                // Or login with
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    'or login with',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  ),
                ),

                const SizedBox(height: 20),

                // Social buttons - exact layout from screenshot
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialLoginButton(
                      icon: FontAwesomeIcons.facebookF,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 20),
                    _socialLoginButton(
                      icon: FontAwesomeIcons.google,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 20),
                    _socialLoginButton(
                      icon: FontAwesomeIcons.apple,
                      color: Colors.black,
                    ),
                  ],
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

  Widget _socialLoginButton({required IconData icon, required Color color}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Center(child: FaIcon(icon, color: color, size: 20)),
    );
  }
}
