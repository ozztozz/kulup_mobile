import "package:flutter/material.dart";

import "features/auth/auth_service.dart";
import "features/auth/login_page.dart";
import "features/dashboard/dashboard_page.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KulupApp());
}

class KulupApp extends StatelessWidget {
  const KulupApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E5A78)),
      useMaterial3: true,
    );

    return MaterialApp(
      title: "Kulup Mobile",
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return HeroMode(
          enabled: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F7FB),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: base.colorScheme.surface,
          foregroundColor: base.colorScheme.onSurface,
          titleTextStyle: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: base.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: base.colorScheme.primary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textTheme: base.textTheme.copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  final AuthService _authService = AuthService();
  bool _checkingSession = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasSession = await _authService.hasSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _authenticated = hasSession;
      _checkingSession = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _authenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_authenticated) {
      return DashboardPage(onLogout: _onLogout);
    }

    return LoginPage(onLoginSuccess: _onLoginSuccess);
  }
}
