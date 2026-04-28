import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Kutucuklardaki yazıları anında okumak için "Kontrolcüler"
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  // 2. Servisimize ulaşmak için bir nesne
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Gölgeyi kaldırır
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ), // Geri butonunu belirginleştirir
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // Klavye açılınca ekran taşmasın diye
          child: Column(
            children: [
              Text(
                "Kayıt Ol",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 138, 52, 96),
                ),
              ),

              const SizedBox(height: 30),

              // Ad Kutucuğu
              TextField(
                controller: _adController,
                decoration: const InputDecoration(
                  labelText: "Ad",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Soyad Kutucuğu
              TextField(
                controller: _soyadController,
                decoration: const InputDecoration(
                  labelText: "Soyad",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Email Kutucuğu
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Şifre Kutucuğu
              TextField(
                controller: _sifreController,
                obscureText: true, // Yazıyı gizle (nokta nokta göster)
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // KAYIT BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Butona basıldığında servisteki fonksiyonu çağırıyoruz
                    String? sonuc = await _authService.kayitOl(
                      _emailController.text,
                      _sifreController.text,
                      _adController.text,
                      _soyadController.text,
                    );

                    if (sonuc == "Başarılı") {
                      // Kayıt başarılıysa bir uyarı ver ve geri dön
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Kayıt Başarılı! Giriş yapabilirsiniz.",
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      // Hata varsa ekranda göster
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Hata: $sonuc")));
                    }
                  },
                  child: const Text(
                    "Kaydı Tamamla",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 52, 138, 118),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
