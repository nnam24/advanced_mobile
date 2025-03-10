import 'package:flutter/material.dart';
import 'package:final_application/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'ve sent a verification email to your inbox. Please check your email and click the verification link to activate your account.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Back to Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    try {
                      final email = supabase.auth.currentUser?.email;
                      if (email != null) {
                        await supabase.auth.resend(
                          type: OtpType.signup,
                          email: email,
                        );
                        if (context.mounted) {
                          context.showSnackBar('Verification email resent');
                        }
                      }
                    } catch (error) {
                      if (context.mounted) {
                        context.showSnackBar('Failed to resend verification email', isError: true);
                      }
                    }
                  },
                  child: const Text('Resend Verification Email'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

