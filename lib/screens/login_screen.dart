import 'package:flutter/material.dart';
import 'package:task_calendar/screens/home_screen.dart';
import '../services/auth_service.dart';
import 'register_screen.dart'; // Kayıt sayfasına gitmek için
import 'home_screen.dart'; // Giriş başarılıysa ana sayfaya gitmek için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.indigo),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _sifreController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // GİRİŞ BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  String? sonuc = await _authService.girisYap(
                    _emailController.text,
                    _sifreController.text,
                  );
                  if (sonuc == "Başarılı") {
                    // Giriş başarılı uyarısını yine de kısa bir süre gösterebiliriz
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Giriş Başarılı! Hoş geldin."),
                      ),
                    );

                    // ANA SAYFAYA YÖNLENDİRME
                    // Navigator.pushReplacement kullanıyoruz ki geri dönüldüğünde login ekranı gelmesin.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Hata: $sonuc")));
                  }
                },
                child: const Text("Giriş Yap"),
              ),
            ),

            // KAYIT OL SAYFASINA GİT
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Hesabınız yok mu? Kayıt Olun"),
            ),
          ],
        ),
      ),
    );
  }
}
