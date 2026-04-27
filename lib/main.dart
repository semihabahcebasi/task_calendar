import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_calendar/screens/login_screen.dart'; // Kendi dosya yoluna göre kontrol et

// GLOBAL DİNLEYİCİ: Uygulama her zaman Light (Aydınlık) modda başlar!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

          home: const LoginScreen(),
        );
      },
    );
  }
}
