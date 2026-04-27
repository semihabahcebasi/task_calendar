import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart'; // themeNotifier'a ulaşmak için (Hata verirse Ctrl+. ile düzelt)
import 'package:shared_preferences/shared_preferences.dart'; // Hafızaya yazmak için

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // --- ZAMAN VE TARİH YÖNETİMİ ---
  DateTime simdi = DateTime.now();
  int get ayinGunSayisi => DateUtils.getDaysInMonth(simdi.year, simdi.month);

  final List<String> aylar = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  // İçinde bulunduğumuz ayın adını dinamik olarak alır
  String get suAnkiAyAdi => aylar[simdi.month - 1];

  // Geçmiş gün kontrolü (Güvenlik Kalkanı)
  bool gecmisGunMu(int gun) {
    DateTime secilenGun = DateTime(simdi.year, simdi.month, gun);
    DateTime bugun = DateTime(simdi.year, simdi.month, simdi.day);
    return secilenGun.isBefore(bugun);
  }

  // --- ALT PANEL (Görevleri Gösterme) ---
  void _gorevleriGoster(int gunNo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavye açılınca da genişleyebilmesi için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BAŞLIK (Dinamik Ay Adı ile)
              Text(
                "$gunNo $suAnkiAyAdi Görevleri",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),

              // CANLI GÖREV LİSTESİ
              StreamBuilder<QuerySnapshot>(
                stream: _authService.gorevleriGetir(
                  "$gunNo $suAnkiAyAdi",
                ), // Dinamik Tarih
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Hata Detayı: ${snapshot.error}"),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Bu gün için bir görev yok."),
                    );
                  }

                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var veri = docs[index];
                        return ListTile(
                          leading: IconButton(
                            icon: Icon(
                              veri["tamamlandi"]
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: veri["tamamlandi"]
                                  ? Colors.green
                                  : Colors.indigo,
                            ),
                            // Geçmişse tıklanamaz (null), değilse durumu değiştir
                            onPressed: gecmisGunMu(gunNo)
                                ? null
                                : () {
                                    _authService.gorevDurumDegistir(
                                      veri.id,
                                      !veri["tamamlandi"],
                                    );
                                  },
                          ),
                          title: Text(
                            veri["baslik"],
                            style: TextStyle(
                              decoration: veri["tamamlandi"]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: veri["tamamlandi"]
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: gecmisGunMu(gunNo)
                                  ? Colors.grey
                                  : Colors.red,
                            ),
                            // Geçmişse silinemez (null), değilse sil
                            onPressed: gecmisGunMu(gunNo)
                                ? null
                                : () => _authService.gorevSil(veri.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // GÖREV EKLEME BUTONU (Sadece bugün ve gelecek için aktif)
              if (!gecmisGunMu(gunNo))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      TextEditingController _gorevController =
                          TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Yeni Görev"),
                          content: TextField(
                            controller: _gorevController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: "Görev başlığını yazın",
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("İptal"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (_gorevController.text.isNotEmpty) {
                                  await _authService.gorevEkle(
                                    _gorevController.text,
                                    "$gunNo $suAnkiAyAdi", // Dinamik Tarih Kaydı
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Ekle"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Yeni Görev Ekle"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.grey[100], // Tema tarafından yönetildiği için artık gerek yok
      appBar: AppBar(
        title: Text("$suAnkiAyAdi ${simdi.year}"), // Dinamik Yıl ve Ay
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 1. TEMA DEĞİŞTİRME BUTONU
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) {
              return IconButton(
                // Tema açıksa koyu mod (ay), koyuysa açık mod (güneş) ikonu göster
                icon: Icon(
                  mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () async {
                  // Mevcut durumun ne olduğunu bul
                  bool isDark = mode == ThemeMode.dark;

                  // Temayı anında tam tersine çevir
                  themeNotifier.value = isDark
                      ? ThemeMode.light
                      : ThemeMode.dark;

                  // Kullanıcının bu yeni tercihini telefonun hafızasına kaydet
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool('isDarkMode', !isDark);
                },
              );
            },
          ),

          // 2. ÇIKIŞ YAP BUTONU (Zaten var olan kodun)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.cikisYap();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: ayinGunSayisi,
                itemBuilder: (context, index) {
                  int gun = index + 1;
                  String tarihAnahtari = "$gun $suAnkiAyAdi";

                  // EKRANIN GECE MODUNDA OLUP OLMADIĞINI ANLAYAN RADAR
                  bool isDark = Theme.of(context).brightness == Brightness.dark;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _authService.gorevleriGetir(tarihAnahtari),
                    builder: (context, snapshot) {
                      double yuzde = 0.0;
                      int toplamGorev = 0;

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        var docs = snapshot.data!.docs;
                        toplamGorev = docs.length;
                        int tamamlanan = docs
                            .where((doc) => doc["tamamlandi"] == true)
                            .length;
                        yuzde = tamamlanan / toplamGorev;
                      }

                      bool bugunMu = (gun == simdi.day);

                      return GestureDetector(
                        onTap: () => _gorevleriGoster(gun),
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              // Kenarlık Rengi: Gece ve Gündüze göre dinamik
                              color: bugunMu
                                  ? (isDark
                                        ? Colors.indigoAccent
                                        : Colors.indigo)
                                  : (isDark
                                        ? Colors.white24
                                        : Colors.indigo.withOpacity(0.2)),
                              width: bugunMu ? 2.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 1. BOYAMA KATMANI
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  widthFactor: 1.0,
                                  heightFactor: yuzde,
                                  child: Container(
                                    // Dolgu Rengi: Gece modunda renkleri daha parlak yapıyoruz
                                    color: yuzde == 1.0
                                        ? (isDark
                                              ? Colors.greenAccent.withOpacity(
                                                  0.4,
                                                )
                                              : const Color.fromARGB(
                                                  255,
                                                  42,
                                                  244,
                                                  49,
                                                ).withOpacity(0.4))
                                        : (isDark
                                              ? Colors.redAccent.withOpacity(
                                                  0.4,
                                                )
                                              : const Color.fromARGB(
                                                  255,
                                                  255,
                                                  2,
                                                  2,
                                                ).withOpacity(0.2)),
                                  ),
                                ),
                              ),
                              // 2. YAZI KATMANI
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$gun",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: bugunMu
                                            ? FontWeight.w900
                                            : FontWeight.bold,
                                        // Gün sayısı rengi
                                        color: isDark
                                            ? Colors.white
                                            : (yuzde > 0.5
                                                  ? Colors.indigo[900]
                                                  : Colors.indigo),
                                      ),
                                    ),
                                    if (toplamGorev > 0)
                                      Text(
                                        "%${(yuzde * 100).toInt()}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          // Yüzdelik yazı rengi
                                          color: isDark
                                              ? (yuzde == 1.0
                                                    ? Colors.greenAccent
                                                    : Colors.white70)
                                              : (yuzde == 1.0
                                                    ? Colors.green[800]
                                                    : (yuzde > 0.5
                                                          ? Colors.indigo[800]
                                                          : Colors.indigo
                                                                .withOpacity(
                                                                  0.6,
                                                                ))),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
