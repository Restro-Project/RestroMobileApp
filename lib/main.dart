import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restro/presentation/pages/auth/login_page.dart';
import 'package:restro/presentation/pages/auth/signup_page.dart';
import 'package:restro/presentation/pages/home/home_page.dart';
import 'package:restro/presentation/pages/onboarding_page.dart';
import 'package:restro/presentation/pages/splash_page.dart';

import 'firebase_options.dart';
import 'presentation/bloc/auth/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(FirebaseAuth.instance)),   // ⬅️  Provider AuthBloc
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'NeuReCare',
        theme: ThemeData(useMaterial3: false, primarySwatch: Colors.green),
        routerConfig: router,
      ),
    );
  }
}