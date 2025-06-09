import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart'; // Import camera package
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/signup_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/profile/account_info_page.dart';
import 'presentation/pages/profile/patient_info_page.dart';
import 'presentation/pages/profile/health_info_page.dart';
import 'presentation/pages/home/chat_detail_page.dart';

List<CameraDescription> cameras = []; // Global variable to store available cameras

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  // Initialize cameras here
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
  runApp(const MyApp());
}

/* ---------- listenable yg mem-push notify setiap AuthBloc berubah ---------- */
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._bloc) {
    _sub = _bloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _bloc;
  late final StreamSubscription _sub;
  bool get loggedIn => _bloc.isLoggedIn;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc();                // satu-satunya instance
    final authNotifier = AuthNotifier(authBloc);

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: authNotifier,
      redirect: (ctx, state) {
        final loggedIn = authNotifier.loggedIn;
        final loc = state.matchedLocation;

        final guestPages = {'/', '/login', '/signup', '/onboarding'};

        if (!loggedIn && !guestPages.contains(loc)) return '/login';
        if (loggedIn && guestPages.contains(loc))   return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/',           builder: (_, __) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/login',      builder: (_, __) => const LoginPage()),
        GoRoute(path: '/signup',     builder: (_, __) => const SignUpPage()),
        GoRoute(path: '/home',       builder: (_, __) => HomePage(cameras: cameras)), // Pass cameras to HomePage
        GoRoute(path: '/account-info', builder: (_, __) => const AccountInfoPage()),
        GoRoute(path: '/patient-info', builder: (_, __) => const PatientInfoPage()),
        GoRoute(path: '/health-info',  builder: (_, __) => const HealthInfoPage()),
        // GoRoute(
        //   path: '/chat/:cid',
        //   builder: (ctx, state) {
        //     final extra = state.extra! as Map;
        //     return ChatDetailPage(
        //       chatId   : state.pathParameters['cid']!,
        //       peerUid  : extra['peerUid'],
        //       peerName : extra['fullName'],
        //       peerPhoto: extra['photo'],
        //     );
        //   },
        // ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Restro',
        theme: ThemeData(useMaterial3: false, primarySwatch: Colors.green),
        routerConfig: router,
      ),
    );
  }
}