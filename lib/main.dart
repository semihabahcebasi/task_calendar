import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_calendar/screens/login_screen.dart'; // Kendi dosya yoluna göre kontrol et
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_calendar/screens/home_screen.dart';
import 'package:task_calendar/screens/analysis_screen.dart';
import 'package:task_calendar/screens/profile_screen.dart';
import 'package:task_calendar/firebase_options.dart';

// GLOBAL DİNLEYİCİ: Uygulama her zaman Light (Aydınlık) modda başlar!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  // YENİ - bununla değiştirin
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Artık SharedPreferences ile cihaz hafızasına bakmıyoruz (KISS Prensibi).
  // Çıkış yapılıp tekrar girildiğinde veya uygulama ilk açıldığında
  // tema her zaman varsayılan aydınlık mod olacaktır.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder: themeNotifier değiştiğinde tüm uygulamayı yeniden çizer
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Görev Takvimi',
          debugShowCheckedModeBanner: false,

          // Tema Modunu buraya bağlıyoruz
          themeMode: currentMode,

          // AÇIK TEMA AYARLARI
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.indigo,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),

          // KOYU TEMA AYARLARI
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.indigoAccent,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),

          // home: const LoginScreen(), // BU SATIRI SİLİP AŞAĞIDAKİNİ EKLİYORUZ
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Eğer Firebase ile bağlantı kurulurken bekleniyorsa, dönen bir çember göster
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Eğer snapshot içinde data varsa (yani kullanıcı önceden giriş yapmışsa)
              if (snapshot.hasData) {
                return const MainScreen(); // ← HomeScreen yerine
              }
              // Eğer kullanıcı giriş yapmamışsa veya kendi isteğiyle çıkış yapmışsa
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _secilenIndex = 0;

  final List<Widget> _sayfalar = [
    const HomeScreen(),
    const AnalizScreen(),
    const ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_secilenIndex],
      bottomNavigationBar: BottomNavigationBar(
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
