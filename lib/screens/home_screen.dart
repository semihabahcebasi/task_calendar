import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Çıkış yapınca login ekranına dönmek için

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mayıs ayı için sabit gün sayısı (İleride bunu DateTime ile dinamik yapacağız)
  final int gunSayisi = 31;
  final AuthService _authService = AuthService();

  // Taslağındaki o meşhur "Click" olayını gerçekleştiren fonksiyon
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
              // 1. BAŞLIK (Kalsın dedik)
              Text(
                "$gunNo Mayıs Görevleri",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),

              // 2. CANLI VERİ AKIŞI (StreamBuilder buraya geldi)
              // Burası Firebase'i sürekli dinler, bir değişim olunca listeyi yeniler.
              StreamBuilder<QuerySnapshot>(
                stream: _authService.gorevleriGetir("$gunNo Mayıs"),
                builder: (context, snapshot) {
                  // StreamBuilder içindeki hata kontrolünü şöyle güncelle:
                  if (snapshot.hasError) {
                    // Bu satır hatayı ekrana "kabak gibi" yazdıracaktır
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
                      child: Text("Bugün için bir görev yok."),
                    );
                  }

                  return SizedBox(
                    height: 250, // Listenin yüksekliği
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var veri = docs[index];
                        return ListTile(
                          leading: IconButton(
                            icon: Icon(
                              // Mantık: Eğer veri["tamamlandi"] true ise dolu ikon, değilse boş ikon
                              veri["tamamlandi"]
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,

                              color: veri["tamamlandi"]
                                  ? Colors.pink
                                  : Colors.indigo,
                            ),
                            onPressed: () {
                              // Mevcut durumun tam tersini gönderiyoruz (Toggle mantığı)
                              _authService.gorevDurumDegistir(
                                veri.id,
                                !veri["tamamlandi"],
                              );
                            },
                          ),
                          title: Text(
                            veri["baslik"],
                            style: TextStyle(
                              // Mantık: Eğer tamamladi true ise üzerini çiz, değilse normal bırak
                              decoration: veri["tamamlandi"]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: veri["tamamlandi"]
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _authService.gorevSil(veri.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // 3. GÖREV EKLEME BUTONU (Bu da kalsın)
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
                                  "$gunNo Mayıs",
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mayıs 2026"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        // Actions: Sağ üst köşeye eklenecek butonlar listesi
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Firebase oturumunu kapat
              await _authService.cikisYap();

              // 2. Login ekranına geri dön ve geçmişi temizle
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) =>
                    false, // Bu 'false', arkada hiçbir sayfa bırakma demektir
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Takvim Izgarası
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // Haftanın 7 günü
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: gunSayisi,
                itemBuilder: (context, index) {
                  int gun = index + 1;
                  return GestureDetector(
                    onTap: () => _gorevleriGoster(gun), // Tıklama tetikleyici
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$gun",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ),
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
