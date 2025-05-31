import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:restro/presentation/pages/home/chat_detail_page.dart';
import 'firebase_options.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/signup_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/profile/account_info_page.dart';
import 'presentation/pages/profile/patient_info_page.dart';
import 'presentation/pages/profile/health_info_page.dart';

/* helper agar GoRouter “mendengar” authStateChanges */
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('*');
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
      refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      redirect: (_, state) {
        final user = FirebaseAuth.instance.currentUser;
        final loc = state.matchedLocation;                 // route saat ini

        if (loc == '/') return null;

        if (user == null &&
            !(loc == '/login' || loc == '/signup' || loc == '/onboarding')) {
          return '/login';
        }

        if (user != null &&
            (loc == '/login' || loc == '/signup' || loc == '/onboarding')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/account-info',  builder: (_, __) => const AccountInfoPage()),
        GoRoute(path: '/patient-info',  builder: (_, __) => const PatientInfoPage()),
        GoRoute(path: '/health-info',   builder: (_, __) => const HealthInfoPage()),
        GoRoute(
          path: '/chat/:cid',
          builder: (ctx, state) {
            final extra = state.extra! as Map;         // peerUid, fullName, photo
            return ChatDetailPage(
              chatId   : state.pathParameters['cid']!,
              peerUid  : extra['peerUid'],
              peerName : extra['fullName'],
              peerPhoto: extra['photo'],
            );
          },
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(FirebaseAuth.instance)),
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
