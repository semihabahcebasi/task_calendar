import 'package:firebase_core/firebase_core.dart'; // 1. Firebase çekirdeği
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // 2. Otomatik oluşan ayar dosyası
//import 'screens/register_screen.dart'; // 3. Senin oluşturduğun kayıt ekranı
import 'screens/login_screen.dart';

void main() async {
  // Uygulama başlamadan önce Flutter bileşenlerinin hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase motorunu, oluşturduğumuz ayarlar ile ateşliyoruz
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // O sağ üstteki kırmızı bandı kaldıralım
      title: 'Takvim Görev Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Uygulama açıldığında doğrudan senin defterdeki o kayıt sayfasına gitsin
      home: const LoginScreen(),
    );
  }
}
