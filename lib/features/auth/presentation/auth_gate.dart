import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  static const _allowedEmails = {
    'alex@themasterycompany.com',
    'olga@themasterycompany.com',
    'grace@themasterycompany.com',
  };

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      final email = user?.email?.toLowerCase();
      final isAllowed =
          user != null &&
          user.emailVerified &&
          email != null &&
          _allowedEmails.contains(email);
      if (user != null && !isAllowed) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => FirebaseAuth.instance.signOut(),
        );
      }
      return isAllowed ? child : const LoginPage();
    },
  );
}
