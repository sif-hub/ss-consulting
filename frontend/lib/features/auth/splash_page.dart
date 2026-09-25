import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/role_router.dart';
import '../../core/auth/token_storage.dart';
import 'login_page.dart';
import '../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasToken = await TokenStorage().hasToken();

    if (!hasToken) {
      _goToLogin();
      return;
    }

    try {
      final user = await AuthService().getCurrentUser();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoleRouter.dashboardFor(user),
        ),
      );
    } catch (_) {
      await TokenStorage().deleteToken();
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/images/logo.png'),
              width: 160,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
