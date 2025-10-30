import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'forget_password_screen.dart';
import 'package:myapp/screens/auth/constants.dart';
import 'package:myapp/Services/auth_service.dart';
import 'login_screen.dart';

InputDecoration buildInputDecoration(String label) {
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

// --- RegisterPage (Refactored) ---

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  // State variables for the AuthService results
  bool _isLoading = false;
  String? _errorMessage;
  // User? _currentUser; // Not strictly needed for the register screen, but can be kept for consistency

  // Form fields state
  String _name = '';
  String _email = '';
  String _password = '';

  // Mock Service instance
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // Inside class _RegisterPageState extends State<RegisterPage>

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // Reset state and set loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Attempt to register the user
      await _authService.signup(_name, _email, _password);

      if (!mounted) return;

      // --- SUCCESS LOGIC ---
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account Created for: $_name!'),
          backgroundColor: kPrimaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Optionally navigate to LoginScreen or Main App Screen
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;

      // --- FAILURE LOGIC ---
      String messageToDisplay;

      // Check if the error is a standard Exception we threw from AuthService
      if (e is Exception) {
        // Get the clean message string (removes the "Exception: " prefix)
        messageToDisplay = e.toString().replaceFirst('Exception: ', '');
      } else {
        // For any other unexpected Dart error
        messageToDisplay = 'An unexpected error occurred.';
      }

      // Update state to show the error and stop loading
      setState(() {
        _errorMessage = messageToDisplay;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $messageToDisplay'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kHorizontalPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Bar (Back Button)
                _buildTopBar(context),

                // 2. Logo Placement (Centered and separate)
                const SizedBox(height: 100),
                // Placeholder for logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150, // adjust size
                    height: 150,
                  ),
                ),
                const SizedBox(height: 30),

                // 3. Main Content Card
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
                        'Create Account',
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
                        'Start your journey with us!',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: kMutedTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: kAppFont,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Registration Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Field
                            TextFormField(
                              decoration: buildInputDecoration('Full Name'),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your name'
                                          : null,
                              onSaved: (value) => _name = value!,
                            ),
                            const SizedBox(height: 16),
                            // Email Field
                            TextFormField(
                              decoration: buildInputDecoration('Email Address'),
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
                              controller: _passwordController,
                              decoration: buildInputDecoration('Password'),
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
                            const SizedBox(height: 16),
                            // Confirm Password Field
                            TextFormField(
                              decoration: buildInputDecoration(
                                'Confirm Password',
                              ),
                              obscureText: true,
                              style: const TextStyle(
                                fontFamily: kAppFont,
                                color: kDarkTextColor,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            // Forgot Password Link (Kept for consistency, though less common on register)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ForgotPasswordScreen(),
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

                            // Register Button
                            _RegisterButton(
                              isLoading: _isLoading,
                              onPressed: _submitRegistration,
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

                // Sign In Link
                _SignInLink(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
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

// --- Extracted & Reusable Widgets (Unchanged, as they were already StatelessWidget) ---

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        // Button is disabled when loading
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
                  'Sign up',
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
        _buildAestheticSocialIcon(
          icon: FontAwesomeIcons.google,
          color: Colors.red,
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        _buildAestheticSocialIcon(
          icon: FontAwesomeIcons.apple,
          color: kDarkTextColor,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _SignInLink extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInLink({required this.onTap});

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
              TextSpan(text: "Already have an account? "),
              TextSpan(
                text: 'Sign in',
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
