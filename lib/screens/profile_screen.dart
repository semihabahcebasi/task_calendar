import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/tema_picker.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final String? temaKategori;
  final String? temaId;

  const ProfileScreen({super.key, this.temaKategori, this.temaId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String? _kullaniciAdi;
  String _avatarId = 'avatar_1';
  String? _temaKategori;
  String? _temaId;

  bool _veriYukleniyor = true;
  int _toplamPuan = 0;
  double _suBerrakligi = 1.0;

  @override
  void initState() {
    super.initState();
    _temaKategori = widget.temaKategori;
    _temaId = widget.temaId;
    _profilVerileriniYukle();
  }

  Future<void> _profilVerileriniYukle() async {
    try {
      final simdi = DateTime.now();

      // MÜKEMMEL HIZ: Tüm verileri tek tek sırayla değil, AYNI ANDA (Paralel) çekiyoruz!
      final sonuclar = await Future.wait([
        _authService.kullaniciAdiniGetir(),
        _authService.avatarIdGetir(),
        _authService.temaGetir(),
        _authService.haftalikAnalizGetir(),
        _authService.aylikAnalizGetir(simdi.year, simdi.month),
      ]);

      if (mounted) {
        setState(() {
          _kullaniciAdi = sonuclar[0] as String?;
          _avatarId = (sonuclar[1] as String?) ?? 'avatar_1';

          final temaVerisi = sonuclar[2] as Map<String, String?>;
          _temaKategori = temaVerisi['temaKategori'];
          _temaId = temaVerisi['temaId'];

          final haftalikVeri = sonuclar[3] as Map<String, dynamic>;
          final aylikVeri = sonuclar[4] as Map<String, dynamic>;

          _toplamPuan = aylikVeri['toplamPuan'] ?? 0;

          int haftalikGorev = haftalikVeri['toplamGorev'] ?? 0;
          int haftalikTamamlanan = haftalikVeri['tamamlanan'] ?? 0;
          _suBerrakligi = haftalikGorev > 0
              ? (haftalikTamamlanan / haftalikGorev)
              : 1.0;

          _veriYukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _veriYukleniyor = false);
    }
  }

  // --- ŞİFRE DEĞİŞTİRME DİALOGU ---
  void _sifreDegistirDialog() {
    final mevcutController = TextEditingController();
    final yeniController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: mevcutController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mevcut Şifre"),
            ),
            TextField(
              controller: yeniController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Yeni Şifre"),
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
              final sonuc = await _authService.sifreDegistir(
                mevcutController.text,
                yeniController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sonuc == "Başarılı" ? "Şifreniz güncellendi!" : sonuc!,
                    ),
                  ),
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  // --- HESAP SİLME DİALOGU ---
  void _hesapSilDialog() {
    final sifreController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Sil", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Tüm verileriniz kalıcı olarak silinecektir. Onaylamak için şifrenizi girin:",
            ),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Şifre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final sonuc = await _authService.hesabiSil(sifreController.text);
              if (sonuc == "Başarılı") {
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (r) => false,
                  );
                }
              } else {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(sonuc!)));
              }
            },
            child: const Text(
              "Hesabımı Sil",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- AVATAR DEĞİŞTİR (BottomSheet) ---
  void _avatarDegistir() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: AvatarPicker(
          secilenAvatar: _avatarId,
          onAvatarSec: (yeniAvatar) async {
            await _authService.avatarGuncelle(yeniAvatar);
            setState(() => _avatarId = yeniAvatar);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // --- TEMA DEĞİŞTİR (BottomSheet) ---
  void _temaDegistir() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: TemaPicker(
          secilenKategori: _temaKategori,
          secilenTema: _temaId,
          onTemaSec: (kat, id) async {
            await _authService.temaGuncelle(kat, id);
            setState(() {
              _temaKategori = kat;
              _temaId = id;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // Akvaryum Widget'ı (emoji ve animasyonlarla)
  Widget _zenAkvaryumu() {
    final double kirlilikOpakligi = (1.0 - _suBerrakligi).clamp(0.0, 0.7);
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: Colors.brown.withOpacity(kirlilikOpakligi),
          ),
          const Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            child: Text(
              "🪨🪨🪨🪨🪨🪨🪨🪨",
              style: TextStyle(fontSize: 30, letterSpacing: 5),
            ),
          ),
          if (_toplamPuan >= 10)
            const Positioned(
              bottom: 15,
              left: 20,
              child: Text("🌿", style: TextStyle(fontSize: 40)),
            ),
          if (_toplamPuan >= 30)
            const Positioned(
              top: 80,
              right: 40,
              child: Text("🐟", style: TextStyle(fontSize: 45)),
            ),
          //deniz yıldızı
          if (_toplamPuan >= 45)
            const Positioned(
              top: 2,
              right: 190,
              child: Text("🌟", style: TextStyle(fontSize: 20)),
            ),
          if (_toplamPuan >= 45)
            const Positioned(
              top: 20,
              right: 50,
              child: Text("🐙", style: TextStyle(fontSize: 30)),
            ),
          if (_toplamPuan >= 60)
            const Positioned(
              bottom: 10,
              right: 30,
              child: Text("🪴", style: TextStyle(fontSize: 50)),
            ),
          if (_toplamPuan >= 100)
            const Positioned(
              top: 40,
              left: 50,
              child: Text("🐡", style: TextStyle(fontSize: 40)),
            ),
          if (_toplamPuan >= 110)
            const Positioned(
              top: 40,
              left: 50,
              child: Text("🐠", style: TextStyle(fontSize: 40)),
            ),
          // 150 Puanda Yengeç (Altta, sağ köşede dursun)
          if (_toplamPuan >= 150)
            const Positioned(
              bottom: -5,
              right: 10,
              child: Text("🦀", style: TextStyle(fontSize: 35)),
            ),

          // 200 Puanda Deniz Kaplumbağası (Ortalarda yüzsün)
          if (_toplamPuan >= 200)
            const Positioned(
              top: 50,
              left: 100,
              child: Text("🐢", style: TextStyle(fontSize: 40)),
            ),

          // 250 Puanda İstiridye (Zeminde solda dursun)
          if (_toplamPuan >= 250)
            const Positioned(
              bottom: -2,
              left: 60,
              child: Text("🐚", style: TextStyle(fontSize: 30)),
            ),

          // 300 Puanda Ahtapot!
          if (_toplamPuan >= 300)
            const Positioned(
              top: 20,
              right: 90,
              child: Text("🐙", style: TextStyle(fontSize: 50)),
            ),

          // Her zaman görünen tatlı su baloncukları (Puana bağlı değil)
          const Positioned(
            top: 30,
            left: 10,
            child: Text("🫧", style: TextStyle(fontSize: 20)),
          ),
          const Positioned(
            top: 100,
            right: 70,
            child: Text("🫧", style: TextStyle(fontSize: 15)),
          ),
          const Positioned(
            top: 10,
            right: 2,
            child: Text("🫧", style: TextStyle(fontSize: 15)),
          ),
          const Positioned(
            top: 80,
            right: 200,
            child: Text("🫧", style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _ayarlarButonu({
    required IconData ikon,
    required String baslik,
    required VoidCallback onTap,
    Color? renk,
  }) {
    return ListTile(
      leading: Icon(ikon, color: renk ?? Theme.of(context).colorScheme.primary),
      title: Text(
        baslik,
        style: TextStyle(
          color: renk ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF8A3460),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _veriYukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(
                      'assets/avatars/$_avatarId.png',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _kullaniciAdi ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  _zenAkvaryumu(),
                  const Divider(),
                  _ayarlarButonu(
                    ikon: Icons.face,
                    baslik: 'Avatarı Değiştir',
                    onTap: _avatarDegistir,
                  ),
                  _ayarlarButonu(
                    ikon: Icons.wallpaper,
                    baslik: 'Temayı Değiştir',
                    onTap: _temaDegistir,
                  ),
                  _ayarlarButonu(
                    ikon: Icons.lock_reset,
                    baslik: 'Şifreyi Değiştir',
                    onTap: _sifreDegistirDialog,
                  ),
                  _ayarlarButonu(
                    ikon: Icons.logout,
                    baslik: 'Çıkış Yap',
                    onTap: () async {
                      await _authService.cikisYap();
                      if (mounted)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (r) => false,
                        );
                    },
                  ),
                  _ayarlarButonu(
                    ikon: Icons.delete_forever,
                    baslik: 'Hesabı Sil',
                    renk: Colors.red,
                    onTap: _hesapSilDialog,
                  ),
                ],
              ),
            ),
    );
  }
}
