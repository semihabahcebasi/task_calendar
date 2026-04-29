import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // --- KULLANICI ADI ---
  String? _kullaniciAdi;
  String _avatarId = 'avatar_1';

  @override
  void initState() {
    super.initState();
    _kullaniciAdiniGetir();
  }

  Future<void> _kullaniciAdiniGetir() async {
    try {
      final ad = await _authService.kullaniciAdiniGetir();
      final avatarId = await _authService.avatarIdGetir();
      if (mounted) {
        setState(() {
          _kullaniciAdi = ad;
          _avatarId = avatarId ?? 'avatar_1';
        });
      }
    } catch (_) {}
  }

  // --- ZAMAN VE TARİH YÖNETİMİ ---
  // BUG #2 FIX: Computed getter — uygulama açık kalsa bile her zaman doğru günü döndürür
  DateTime get simdi => DateTime.now();

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

  String get suAnkiAyAdi => aylar[simdi.month - 1];

  bool gecmisGunMu(int gun) {
    DateTime secilenGun = DateTime(simdi.year, simdi.month, gun);
    DateTime bugun = DateTime(simdi.year, simdi.month, simdi.day);
    return secilenGun.isBefore(bugun);
  }

  // --- ALT PANEL (Görevleri Gösterme) ---
  void _gorevleriGoster(int gunNo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Text(
                "$gunNo $suAnkiAyAdi Görevleri",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),

              StreamBuilder<QuerySnapshot>(
                stream: _authService.gorevleriGetir("$gunNo $suAnkiAyAdi"),
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
                                  : Theme.of(context).colorScheme.primary,
                            ),
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
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: gecmisGunMu(gunNo)
                                  ? Colors.grey
                                  : Colors.red,
                            ),
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
                                    "$gunNo $suAnkiAyAdi",
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
      appBar: AppBar(
        // AppBar'da artık sadece hoşgeldin mesajı var
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/avatars/$_avatarId.png'),
            ),
            const SizedBox(width: 8),
            _kullaniciAdi == null
                ? const Text("Hoş geldin!")
                : Text("Hoş geldin, $_kullaniciAdi!"),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 138, 52, 96),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () {
                  themeNotifier.value = mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                },
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              themeNotifier.value = ThemeMode.light;
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
            // --- AY / YIL BAŞLIĞI (AppBar'dan buraya taşındı) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
                  final bool isDark = mode == ThemeMode.dark;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.indigo[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$suAnkiAyAdi ${simdi.year}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.indigo[900],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

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

                  // BUG #1 FIX: ValueListenableBuilder ile sarıldı — tema değişince grid hücreleri yeniden inşa edilir
                  return ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, __) {
                      bool isDark = mode == ThemeMode.dark;

                      return StreamBuilder<QuerySnapshot>(
                        stream: _authService.gorevleriGetir(tarihAnahtari),
                        builder: (context, snapshot) {
                          double yuzde = 0.0;
                          int toplamGorev = 0;

                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
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
                                  color: bugunMu
                                      ? (isDark
                                            ? Colors.indigoAccent
                                            : Colors.indigo)
                                      : (isDark
                                            ? Colors.white30
                                            : Colors.indigo.withValues(
                                                alpha: 0.2,
                                              )),
                                  width: bugunMu ? 2.5 : 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      widthFactor: 1.0,
                                      heightFactor: yuzde,
                                      child: Container(
                                        color: yuzde == 1.0
                                            ? (isDark
                                                  ? Colors.greenAccent
                                                        .withValues(alpha: 0.4)
                                                  : Colors.green.withValues(
                                                      alpha: 0.4,
                                                    ))
                                            : (isDark
                                                  ? Colors.pinkAccent
                                                        .withValues(alpha: 0.4)
                                                  : Colors.pink.withValues(
                                                      alpha: 0.2,
                                                    )),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "$gun",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: bugunMu
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.indigo[900],
                                          ),
                                        ),
                                        if (toplamGorev > 0)
                                          Text(
                                            "%${(yuzde * 100).toInt()}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: yuzde == 1.0
                                                  ? (isDark
                                                        ? Colors.greenAccent
                                                        : Colors.green[800])
                                                  : (isDark
                                                        ? Colors.pinkAccent
                                                        : Colors.pink[800]),
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
