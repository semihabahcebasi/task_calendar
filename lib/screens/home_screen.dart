import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/tema_picker.dart';

class HomeScreen extends StatefulWidget {
  final String? temaKategori;
  final String? temaId;

  const HomeScreen({super.key, this.temaKategori, this.temaId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  String? _kullaniciAdi;
  String _avatarId = 'avatar_1';
  String? _temaKategori;
  String? _temaId;

  // --- YENİ: Seçili gün (varsayılan: bugün) ---
  late int _secilenGun;

  @override
  void initState() {
    super.initState();
    _temaKategori = widget.temaKategori;
    _temaId = widget.temaId;
    _secilenGun = DateTime.now().day; // Ekran açılınca bugün seçili gelir
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

  // --- ZAMAN VE TARİH ---
  DateTime _gosterilenTarih = DateTime.now();
  final DateTime _bugun = DateTime.now();

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
    final secilenGun = DateTime(
      _gosterilenTarih.year,
      _gosterilenTarih.month,
      gun,
    );
    final bugun = DateTime(_bugun.year, _bugun.month, _bugun.day);
    return secilenGun.isBefore(bugun);
  }

  void _oncekiAy() {
    setState(() {
      _gosterilenTarih = DateTime(
        _gosterilenTarih.year,
        _gosterilenTarih.month - 1,
        1,
      );
      // Ay değişince o ayın 1'ini seç
      _secilenGun = 1;
    });
  }

  void _sonrakiAy() {
    setState(() {
      _gosterilenTarih = DateTime(
        _gosterilenTarih.year,
        _gosterilenTarih.month + 1,
        1,
      );
      _secilenGun = 1;
    });
  }

  // --- Zorluk butonu (dialog içinde) ---
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

  // --- HÜCREYE TIKLANINCA AÇILAN BOTTOM SHEET ---
  // Görev ekleme + tamamlama işaretleme buradan yapılır
  void _gorevleriGoster(int gunNo) {
    // Önce seçili günü güncelle (panel anında güncellenir)
    setState(() => _secilenGun = gunNo);

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
              // Başlık
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

              // Görev listesi (tamamlama + silme burada)
              StreamBuilder<QuerySnapshot>(
                stream: _authService.gorevleriGetir("$gunNo $gosterilenAyAdi"),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Hata: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

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
                        final veri = docs[index];
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
                                : () => _authService.gorevDurumDegistir(
                                    veri.id,
                                    !veri["tamamlandi"],
                                  ),
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

              // Görev ekleme butonu (sadece geçmiş günlerde gizlenir)
              if (!gecmisGunMu(gunNo))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton.icon(
                    onPressed: () => _gorevEklemeDialoguAc(context, gunNo),
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

  // --- Görev ekleme dialogu (ayrı fonksiyon, temiz kod için) ---
  void _gorevEklemeDialoguAc(BuildContext sheetContext, int gunNo) {
    final gorevController = TextEditingController();
    showDialog(
      context: sheetContext,
      builder: (context) {
        String secilenZorluk = 'kolay';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Yeni Görev",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  TextField(
                    controller: gorevController,
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
                    if (gorevController.text.isNotEmpty) {
                      await _authService.gorevEkle(
                        gorevController.text,
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
  }

  // --- TAKVİMİN ALTINDA SABİT GÖREV PANELİ ---
  Widget _gorevPaneli() {
    // YENİ: Takvimde hangi ay/gün seçili olursa olsun, burası HER ZAMAN GERÇEK BUGÜNÜN tarih anahtarını oluşturur.
    final String bugunAnahtari = "${_bugun.day} ${aylar[_bugun.month - 1]}";

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel başlığı
          Text(
            "Bugünkü görevlerini tamamladın mı $_kullaniciAdi ? ",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Görev listesi — sadece metin, tıklama yok
          StreamBuilder<QuerySnapshot>(
            stream: _authService.gorevleriGetir(
              bugunAnahtari,
            ), // Artık sadece bugünün anahtarını dinliyor
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  "Bugün için görev yok.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: docs.map((doc) {
                  final baslik = doc["baslik"] as String;
                  final tamamlandi = doc["tamamlandi"] as bool;
                  final zorluk = doc["zorluk"] as String? ?? 'kolay';

                  final zorlukRenk = zorluk == 'zor'
                      ? Colors.red
                      : zorluk == 'orta'
                      ? Colors.orange
                      : Colors.green;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tamamlandı göstergesi (sadece görsel, tıklanamaz)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, right: 8),
                          child: Icon(
                            tamamlandi
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 16,
                            color: tamamlandi ? Colors.green : zorlukRenk,
                          ),
                        ),
                        // Görev metni
                        Expanded(
                          child: Text(
                            baslik,
                            style: TextStyle(
                              fontSize: 13,
                              color: tamamlandi
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.45)
                                  : Theme.of(context).colorScheme.onSurface,
                              decoration: tamamlandi
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Alt ipucu yazısı
          const SizedBox(height: 8),
          Text(
            "Görev eklemek veya tamamlamak için yukarıdaki hücrelere dokun.",
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.indigoAccent.withOpacity(
                0.5,
              ), // Resim yüklenene kadar tatlı bir renk
              backgroundImage: AssetImage('assets/avatars/$_avatarId.png'),
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
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
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
          if (_temaKategori != null && _temaId != null)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
              ),
            ),

          // Ana içerik
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // --- Ay/Yıl başlığı ---
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
                          color: const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                size: 30,
                                color: isDark
                                    ? Colors.white70
                                    : const Color.fromARGB(255, 255, 255, 255),
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

                // --- Takvim grid'i (sabit yükseklik) ---
                // --- YENİ: Gün İsimleri Başlığı ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pa"].map((
                      gun,
                    ) {
                      return SizedBox(
                        width: 30,
                        child: Text(
                          gun,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // --- Takvim grid'i (sabit yükseklik) ---
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: Builder(
                    builder: (context) {
                      // YENİ: Ayın 1'i haftanın hangi günü? (1=Pzt, 7=Paz)
                      final int ilkGunHaftaninGunu = DateTime(
                        _gosterilenTarih.year,
                        _gosterilenTarih.month,
                        1,
                      ).weekday;

                      // Eğer ay Cuma (5) başlıyorsa, başına 4 tane boş hücre koymalıyız.
                      final int boslukSayisi = ilkGunHaftaninGunu - 1;
                      final int toplamHucre = boslukSayisi + ayinGunSayisi;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                        itemCount: toplamHucre,
                        itemBuilder: (context, index) {
                          // YENİ: Eğer index boşluk sayısından küçükse, o hücreyi boş bırak (Önceki ayın günleri)
                          if (index < boslukSayisi) {
                            return const SizedBox.shrink();
                          }

                          // Gerçek gün numaramızı hesaplıyoruz
                          int gun = index - boslukSayisi + 1;
                          String tarihAnahtari = "$gun $gosterilenAyAdi";

                          return ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (_, mode, __) {
                              bool isDark = mode == ThemeMode.dark;

                              return StreamBuilder<QuerySnapshot>(
                                stream: _authService.gorevleriGetir(
                                  tarihAnahtari,
                                ),
                                builder: (context, snapshot) {
                                  double yuzde = 0.0;
                                  int toplamGorev = 0;

                                  if (snapshot.hasData &&
                                      snapshot.data!.docs.isNotEmpty) {
                                    final docs = snapshot.data!.docs;
                                    toplamGorev = docs.length;
                                    final tamamlanan = docs
                                        .where(
                                          (doc) => doc["tamamlandi"] == true,
                                        )
                                        .length;
                                    yuzde = tamamlanan / toplamGorev;
                                  }

                                  final bugunMu =
                                      gun == _bugun.day &&
                                      _gosterilenTarih.month == _bugun.month &&
                                      _gosterilenTarih.year == _bugun.year;

                                  final secilenMi = gun == _secilenGun;

                                  return GestureDetector(
                                    onTap: () => _gorevleriGoster(gun),
                                    child: Container(
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                        color: secilenMi
                                            ? (isDark
                                                  ? Colors.indigo.withOpacity(
                                                      0.35,
                                                    )
                                                  : Colors.indigo.withOpacity(
                                                      0.12,
                                                    ))
                                            : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: bugunMu
                                              ? (isDark
                                                    ? Colors.indigoAccent
                                                    : Colors.indigo)
                                              : secilenMi
                                              ? (isDark
                                                    ? Colors.indigoAccent
                                                    : Colors.indigo)
                                              : (isDark
                                                    ? Colors.white30
                                                    : Colors.indigo.withOpacity(
                                                        0.2,
                                                      )),
                                          width: bugunMu || secilenMi
                                              ? 2.5
                                              : 1.0,
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
                                                                .withOpacity(
                                                                  0.4,
                                                                )
                                                          : Colors.green
                                                                .withOpacity(
                                                                  0.4,
                                                                ))
                                                    : (isDark
                                                          ? Colors.pinkAccent
                                                                .withOpacity(
                                                                  0.4,
                                                                )
                                                          : Colors.pink
                                                                .withOpacity(
                                                                  0.2,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: yuzde == 1.0
                                                          ? (isDark
                                                                ? Colors
                                                                      .greenAccent
                                                                : Colors
                                                                      .green[800])
                                                          : (isDark
                                                                ? Colors
                                                                      .pinkAccent
                                                                : Colors
                                                                      .pink[800]),
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
                      );
                    },
                  ),
                ),
                // --- TAKVİMİN ALTINDA SABİT GÖREV PANELİ ---
                Expanded(child: SingleChildScrollView(child: _gorevPaneli())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
