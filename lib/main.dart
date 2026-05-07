import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_calendar/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_calendar/screens/home_screen.dart';
import 'package:task_calendar/screens/analysis_screen.dart';
import 'package:task_calendar/screens/profile_screen.dart';
import 'package:task_calendar/firebase_options.dart';
import 'package:task_calendar/services/auth_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Görev Takvimi',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.indigo,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.indigoAccent,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const SplashScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

// --- SPLASH EKRANI ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _hazirlaVeGec();
  }

  Future<void> _globalCachele(String assetPath) async {
    final ImageProvider provider = AssetImage(assetPath);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<void>();
    stream.addListener(
      ImageStreamListener(
        (_, __) => completer.complete(),
        onError: (_, __) => completer.complete(),
      ),
    );
    await completer.future;
  }

  Future<void> _hazirlaVeGec() async {
    final authService = AuthService();

    final tema = await authService.temaGetir();
    final kategori =
        (tema['temaKategori'] == null || tema['temaKategori']!.isEmpty)
        ? null
        : tema['temaKategori'];
    final temaId = (tema['temaId'] == null || tema['temaId']!.isEmpty)
        ? null
        : tema['temaId'];

    await Future.wait([
      if (kategori != null && temaId != null)
        _globalCachele('assets/temalar/$kategori/$temaId.png'),
      Future.delayed(const Duration(milliseconds: 1000)),
    ]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(temaKategori: kategori, temaId: temaId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 127, 149, 147),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Görev Takvimi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ANA EKRAN ---
class MainScreen extends StatefulWidget {
  final String? temaKategori;
  final String? temaId;

  const MainScreen({super.key, this.temaKategori, this.temaId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _secilenIndex = 0;

  late final List<Widget> _sayfalar;

  @override
  void initState() {
    super.initState();
    _sayfalar = [
      HomeScreen(temaKategori: widget.temaKategori, temaId: widget.temaId),
      const AnalizScreen(),
      const ProfilScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_secilenIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        currentIndex: _secilenIndex,
        onTap: (index) => setState(() => _secilenIndex = index),
        selectedItemColor: const Color.fromARGB(255, 138, 52, 96),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
