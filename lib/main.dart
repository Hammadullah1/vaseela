import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/choose_cause_screen.dart';
import 'screens/user/wallet_screen.dart';
import 'screens/user/requests_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/user/raast_payment_screen.dart';
import 'screens/screen_select_amount.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VaseelaApp());
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final onAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (user == null) {
      return onAuthPage ? null : '/login';
    }

    if (onAuthPage) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthChecker(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(
        onLoggedIn: () => context.go('/home'),
        onAdminLoggedIn: () => context.go('/admin'),
        onSwitchToRegister: () => context.go('/register'),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(
        onRegistered: () => context.go('/login'),
        onSwitchToLogin: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => HomeScreen(
        onHunger: () => context.go('/donate/hunger'),
        onEducation: () => context.go('/donate/education'),
        onCapital: () => context.go('/donate/capital'),
        onHealthcare: () => context.go('/donate/healthcare'),
        onShelter: () => context.go('/donate/shelter'),
        onWater: () => context.go('/donate/water'),
        onChooseCause: () => context.go('/choose-cause'),
        onWallet: () => context.go('/wallet'),
        onLogout: () {
          final router = GoRouter.of(context);
          AuthService.logout().then((_) => router.go('/login'));
        },
      ),
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return '/login';
        final isAdmin = await FirestoreService.isAdmin(user.uid);
        return isAdmin ? null : '/home';
      },
      builder: (context, state) => const AdminPanelScreen(),
    ),
    GoRoute(
      path: '/choose-cause',
      builder: (context, state) => ChooseCauseScreen(
        onCauseSelected: (cause) => context.push('/donate/$cause'),
        onBack: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => WalletScreen(onBack: () => context.go('/home')),
    ),
    GoRoute(
      path: '/requests',
      builder: (context, state) => RequestsScreen(onBack: () => context.go('/home')),
    ),
    GoRoute(
      path: '/donate/:cause',
      builder: (context, state) {
        final cause = state.pathParameters['cause'] ?? 'Cause';
        return ScreenSelectAmount(
          cause: cause,
          onAmountSelected: (amount) => context.push('/payment?cause=$cause&amount=$amount'),
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/choose-cause');
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final cause = state.uri.queryParameters['cause'] ?? 'Cause';
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0.0;
        return RaastPaymentScreen(
          cause: cause,
          amount: amount,
          onPaymentDone: () => context.go('/home'),
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/donate/$cause');
            }
          },
        );
      },
    ),
  ],
);

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.lightGreen,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null || !user.emailVerified) {
          return LoginScreen(
            onLoggedIn: () => context.go('/home'),
            onAdminLoggedIn: () => context.go('/admin'),
            onSwitchToRegister: () => context.go('/register'),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: FirestoreService.getUser(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.lightGreen,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              );
            }

            final data = userSnap.data;
            if (data != null && data['isAdmin'] == true) {
              return const AdminPanelScreen();
            }

            return HomeScreen(
              onHunger: () => context.go('/donate/hunger'),
              onEducation: () => context.go('/donate/education'),
              onCapital: () => context.go('/donate/capital'),
              onHealthcare: () => context.go('/donate/healthcare'),
              onShelter: () => context.go('/donate/shelter'),
              onWater: () => context.go('/donate/water'),
              onChooseCause: () => context.go('/choose-cause'),
              onWallet: () => context.go('/wallet'),
              onLogout: () {
                final router = GoRouter.of(context);
                AuthService.logout().then((_) => router.go('/login'));
              },
            );
          },
        );
      },
    );
  }
}

class VaseelaApp extends StatelessWidget {
  const VaseelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vaseela',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryGreen,
        ),
        scaffoldBackgroundColor: AppColors.white,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
