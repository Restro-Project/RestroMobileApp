import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardDone = prefs.getBool('onboard_done') ?? false;
    final hasToken = prefs.getString('token') != null;

    await Future.delayed(const Duration(seconds: 1));     // logo delay

    if (!mounted) return;
    if (hasToken) {
      context.go('/home');
    } else if (!onboardDone) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(
        body: Center(
          child: Image(
            image: AssetImage('assets/logo.png'),
            width: 120,
          ),
        ),
      );
}
