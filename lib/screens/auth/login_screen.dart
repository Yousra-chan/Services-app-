import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/navigator_bottom.dart';
import 'forget_password_screen.dart';
import 'package:myapp/screens/auth/constants.dart';
import 'package:myapp/Services/auth_service.dart';

InputDecoration buildAestheticInputDecoration(String label) {
  return InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(color: kMutedTextColor, fontFamily: kAppFont),
    filled: true,
    fillColor: kInputFillColor.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 20.0,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
    ),
  );
}

// --- LoginScreen (State Management Already Local) ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  // State for loading status is managed locally inside this State class
  bool _isLoading = false;

  // In a real app, you would inject or create an AuthService here.
  // For this exercise, we just use a simulated delay.
  void _submitLogin() async {
    // Assuming _email and _password are the variables holding the login input
    // and _formKey is a GlobalKey<FormState>

    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Start Loading: Update local state
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        // 1. Call the actual AuthService login function
        await AuthService().login(_email, _password);

        // 2. SUCCESS: Navigate to the NavBottomPage
        // Use pushReplacement to clear the login screen from the navigation stack
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NavigatorBottom()),
        );

        // Note: Because of pushReplacement, the code below this won't execute
        // on this screen, but we still ensure _isLoading is handled below
        // in case of an error.
      } on Exception catch (e) {
        // 3. FAILURE: Handle the error (e.g., show a SnackBar)
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // e.toString().replaceFirst('Exception: ', '') cleans up the message
            content: Text(
              e.toString().replaceFirst('Exception: ', 'Login failed: '),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        // 4. End Loading: Ensure loading state is reset,
        // primarily for the failure case.
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 100),
                // Replaced Image.asset with a centered text logo for runnable code
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: kDarkTextColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: kAppFont,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to your Account',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: kAppFont,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Email Address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty || !value.contains('@')
                                          ? 'Please enter a valid email address'
                                          : null,
                              onSaved: (value) => _email = value!,
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            TextFormField(
                              decoration: buildAestheticInputDecoration(
                                'Password',
                              ),
                              obscureText: true,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.length < 6
                                          ? 'Password must be at least 6 characters'
                                          : null,
                              onSaved: (value) => _password = value!,
                            ),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    fontFamily: kAppFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            _LoginButton(
                              isLoading: _isLoading, // Uses local state
                              onPressed: _submitLogin,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const _OrDivider(),

                      const SizedBox(height: 20),
                      const _SocialSignInRow(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Sign Up Link
                _SignUpLink(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(
          CupertinoIcons.arrow_left,
          color: kMutedTextColor,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

// --- Extracted & Reusable Widgets ---

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: kPrimaryBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withOpacity(0.9),
                    ),
                  ),
                )
                : const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: kAppFont,
                  ),
                ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Divider(color: kBorderColor, height: 1, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              color: kMutedTextColor.withOpacity(0.8),
              fontSize: 14,
              fontFamily: kAppFont,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: kBorderColor, height: 1, thickness: 1),
        ),
      ],
    );
  }
}

class _SocialSignInRow extends StatelessWidget {
  const _SocialSignInRow();

  Widget _buildAestheticSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor.withOpacity(0.7)),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Adjusted the layout to remove an extra SizedBox at the start for better spacing
        _buildAestheticSocialIcon(
          icon: FontAwesomeIcons.google,
          color: Colors.red,
          onPressed: () {
            // Placeholder for Google Sign In
          },
        ),
        const SizedBox(width: 12),
        _buildAestheticSocialIcon(
          icon: FontAwesomeIcons.apple,
          color: kDarkTextColor,
          onPressed: () {
            // Placeholder for Apple Sign In
          },
        ),
      ],
    );
  }
}

class _SignUpLink extends StatelessWidget {
  final VoidCallback onTap;

  const _SignUpLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              color: kMutedTextColor,
              fontFamily: kAppFont,
              fontSize: 15,
            ),
            children: [
              TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign up now',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
