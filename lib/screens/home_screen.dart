import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/tema_picker.dart';

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

  String? _temaKategori;
  String? _temaId;

  @override
  void initState() {
    super.initState();
    _kullaniciAdiniGetir();
  }

  // KULLANICI ADI GETİRME
  Future<void> _kullaniciAdiniGetir() async {
    try {
      final ad = await _authService.kullaniciAdiniGetir();
      final avatarId = await _authService.avatarIdGetir();
      final tema = await _authService.temaGetir();

      final kategori =
          (tema['temaKategori'] == null || tema['temaKategori']!.isEmpty)
          ? null
          : tema['temaKategori'];
      final temaId = (tema['temaId'] == null || tema['temaId']!.isEmpty)
          ? null
          : tema['temaId'];

      // Önce görseli cache'le — bitmeden setState çağırma
      if (kategori != null && temaId != null && mounted) {
        await precacheImage(
          AssetImage('assets/temalar/$kategori/$temaId.png'),
          context,
        );
      }

      // Görsel hazır, şimdi state'i güncelle — anında gelir
      if (mounted) {
        setState(() {
          _kullaniciAdi = ad;
          _avatarId = avatarId ?? 'avatar_1';
          _temaKategori = kategori;
          _temaId = temaId;
        });
      }
    } catch (_) {}
  }

  // AVATAR DEĞİŞTİRME
  void _avatarDegistir() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profil resmini değiştir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AvatarPicker(
                secilenAvatar: _avatarId,
                onAvatarSec: (yeniAvatar) async {
                  await _authService.avatarGuncelle(yeniAvatar);
                  setState(() {
                    _avatarId = yeniAvatar;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TEMA DEĞİŞTİRME ---
  void _temaDegistir() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tema seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TemaPicker(
                secilenKategori: _temaKategori,
                secilenTema: _temaId,
                //gecikmeyi önlemek için önce görseli cache'le, sonra kaydet ve state'i güncelle
                onTemaSec: (kategori, temaId) async {
                  // Önce yeni görseli cache'le
                  await precacheImage(
                    AssetImage('assets/temalar/$kategori/$temaId.png'),
                    context,
                  );

                  // Sonra kaydet ve state'i güncelle — artık gecikme olmaz
                  await _authService.temaGuncelle(kategori, temaId);
                  setState(() {
                    _temaKategori = kategori;
                    _temaId = temaId;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await _authService.temaGuncelle('', '');
                  setState(() {
                    _temaKategori = null;
                    _temaId = null;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text(
                  'Temayı kaldır',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ZAMAN VE TARİH YÖNETİMİ ---
  DateTime _gosterilenTarih = DateTime.now(); // Ekranda görünen ay/yıl
  final DateTime _bugun = DateTime.now(); // Gerçek bugünü referans almak için

  int get ayinGunSayisi =>
      DateUtils.getDaysInMonth(_gosterilenTarih.year, _gosterilenTarih.month);

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

  String get gosterilenAyAdi => aylar[_gosterilenTarih.month - 1];

  bool gecmisGunMu(int gun) {
    DateTime secilenGun = DateTime(
      _gosterilenTarih.year,
      _gosterilenTarih.month,
      gun,
    );
    DateTime bugun = DateTime(_bugun.year, _bugun.month, _bugun.day);
    return secilenGun.isBefore(bugun);
  }

  // Ay değiştirme fonksiyonları
  void _oncekiAy() {
    setState(() {
      _gosterilenTarih = DateTime(
        _gosterilenTarih.year,
        _gosterilenTarih.month - 1,
        1,
      );
    });
  }

  void _sonrakiAy() {
    setState(() {
      _gosterilenTarih = DateTime(
        _gosterilenTarih.year,
        _gosterilenTarih.month + 1,
        1,
      );
    });
  }

  Widget _zorlukButonu(
    String zorluk,
    String puan,
    Color renk,
    String secilen,
    StateSetter setStateDialog,
    Function(String) onSec,
  ) {
    final aktif = zorluk == secilen;
    return GestureDetector(
      onTap: () => setStateDialog(() => onSec(zorluk)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: aktif ? renk : renk.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: renk),
        ),
        child: Text(
          '${zorluk[0].toUpperCase()}${zorluk.substring(1)} $puan',
          style: TextStyle(
            color: aktif ? Colors.white : renk,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
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
                "$gunNo $gosterilenAyAdi Görevleri",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),

              StreamBuilder<QuerySnapshot>(
                stream: _authService.gorevleriGetir("$gunNo $gosterilenAyAdi"),
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
                        builder: (context) {
                          String secilenZorluk = 'kolay';
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              return AlertDialog(
                                title: const Text("Yeni Görev"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _zorlukButonu(
                                          'kolay',
                                          '+1',
                                          Colors.green,
                                          secilenZorluk,
                                          setStateDialog,
                                          (v) => secilenZorluk = v,
                                        ),
                                        _zorlukButonu(
                                          'orta',
                                          '+3',
                                          Colors.orange,
                                          secilenZorluk,
                                          setStateDialog,
                                          (v) => secilenZorluk = v,
                                        ),
                                        _zorlukButonu(
                                          'zor',
                                          '+5',
                                          Colors.red,
                                          secilenZorluk,
                                          setStateDialog,
                                          (v) => secilenZorluk = v,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    //const SizedBox(height: 8),
                                    TextField(
                                      controller: _gorevController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: "Görev başlığını yazın",
                                      ),
                                    ),
                                  ],
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
                                          "$gunNo $gosterilenAyAdi",
                                          secilenZorluk,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text("Ekle"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
          mainAxisSize: MainAxisSize.max,
          children: [
            GestureDetector(
              onTap: () => _avatarDegistir(),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/avatars/$_avatarId.png'),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _kullaniciAdi == null
                    ? "Hoş geldin!"
                    : "Selam, $_kullaniciAdi!",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 127, 149, 147),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: () => _temaDegistir(),
          ),
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
      body: Stack(
        children: [
          // Arka plan görseli
          if (_temaKategori != null && _temaId != null)
            Positioned.fill(
              child: Image.asset(
                'assets/temalar/$_temaKategori/$_temaId.png',
                fit: BoxFit.cover,
              ),
            ),
          // Şeffaf katman
          if (_temaKategori != null && _temaId != null)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // --- AY / YIL BAŞLIĞI (AppBar'dan buraya taşındı) ---
                // --- AY / YIL BAŞLIĞI ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, __) {
                      final bool isDark = mode == ThemeMode.dark;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sol Ok (Önceki Ay)
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                size: 30,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.indigo[700],
                              ),
                              onPressed: _oncekiAy,
                            ),

                            Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.indigo[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "$gosterilenAyAdi ${_gosterilenTarih.year}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : Colors.indigo[900],
                                letterSpacing: 0.5,
                              ),
                            ),

                            // Sağ Ok (Sonraki Ay)
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                size: 30,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.indigo[700],
                              ),
                              onPressed: _sonrakiAy,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: ayinGunSayisi,
                    itemBuilder: (context, index) {
                      int gun = index + 1;
                      String tarihAnahtari = "$gun $gosterilenAyAdi";
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

                              bool bugunMu =
                                  (gun == _bugun.day &&
                                  _gosterilenTarih.month == _bugun.month &&
                                  _gosterilenTarih.year == _bugun.year);
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
                                                            .withValues(
                                                              alpha: 0.4,
                                                            )
                                                      : Colors.green.withValues(
                                                          alpha: 0.4,
                                                        ))
                                                : (isDark
                                                      ? Colors.pinkAccent
                                                            .withValues(
                                                              alpha: 0.4,
                                                            )
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
        ],
      ),
    );
  }
}
