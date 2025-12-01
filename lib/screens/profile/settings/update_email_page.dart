import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screens/profile/profile_constants.dart';

class UpdateEmailPage extends StatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Update email
      await user.verifyBeforeUpdateEmail(_newEmailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent to new address'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update email';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already in use';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: kDangerColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update email: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kLightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Update Email",
          style: TextStyle(
            color: kLightTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Email
              if (currentUser?.email != null) ...[
                const Text(
                  'Current Email:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kDarkTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentUser!.email!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: kMutedTextColor,
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock, color: kPrimaryBlue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: kMutedTextColor,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                    borderSide:
                        BorderSide(color: kMutedTextColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                    borderSide:
                        BorderSide(color: kMutedTextColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                    borderSide: const BorderSide(color: kPrimaryBlue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New Email
              TextFormField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'New Email Address',
                  prefixIcon: const Icon(Icons.email, color: kPrimaryBlue),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                    borderSide:
                        BorderSide(color: kMutedTextColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // FIXED: Added .0
                    borderSide: const BorderSide(color: kPrimaryBlue),
                  ),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWarningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0), // FIXED: Added .0
                  border: Border.all(color: kWarningColor.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kWarningColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• You will need to verify your new email address'),
                    Text(
                        '• A verification email will be sent to the new address'),
                    Text('• Your email will not change until verified'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Update Email Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // FIXED: Added .0
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
