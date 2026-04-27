import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_calendar/screens/login_screen.dart';

// GLOBAL DİNLEYİCİ: Tüm uygulama bu değişkeni dinleyecek
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Uygulama açılırken telefonun hafızasına (Local Storage) bakıyoruz
  final prefs = await SharedPreferences.getInstance();

  // 2. 'isDarkMode' adında bir kayıt var mı? Yoksa varsayılan olarak false (açık) yap.
  final bool isDark = prefs.getBool('isDarkMode') ?? false;

  // 3. Dinleyiciye başlangıç değerini veriyoruz
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

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
              // Burayı değiştirdik: Koyu temada da AppBar rengi indigo olsun
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),

          home:
              const LoginScreen(), // Uygulama açıldığında LoginScreen gösterilecek
        );
      },
    );
  }
}
