import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- KAYIT OL ---
  Future<String?> kayitOl(
    String email,
    String password,
    String ad,
    String soyad,
    String avatarId,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      await _firestore.collection("Users").doc(user!.uid).set({
        "ad": ad,
        "soyad": soyad,
        "email": email,
        'avatarId': avatarId,
      });
      return "Başarılı";
    } catch (e) {
      return e.toString();
    }
  }

  // --- GİRİŞ YAP ---
  Future<String?> girisYap(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Başarılı";
    } catch (e) {
      return e.toString();
    }
  }

  // --- GÖREV EKLE ---
  Future<void> gorevEkle(String baslik, String tarih, String zorluk) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection("Tasks").add({
      "userId": uid,
      "baslik": baslik,
      "tarih": tarih,
      "zorluk": zorluk,
      "tamamlandi": false,
      "olusturmaTarihi": FieldValue.serverTimestamp(),
    });
  }

  // --- GÖREVLERİ GETİR (stream) ---
  Stream<QuerySnapshot> gorevleriGetir(String tarih) {
    String uid = _auth.currentUser!.uid;
    return _firestore
        .collection("Tasks")
        .where("userId", isEqualTo: uid)
        .where("tarih", isEqualTo: tarih)
        .orderBy("olusturmaTarihi", descending: true)
        .snapshots();
  }

  // --- GÖREV SİL ---
  Future<void> gorevSil(String docId) async {
    await _firestore.collection("Tasks").doc(docId).delete();
  }

  // --- GÖREV DURUM DEĞİŞTİR ---
  Future<void> gorevDurumDegistir(String docId, bool yeniDurum) async {
    await _firestore.collection("Tasks").doc(docId).update({
      "tamamlandi": yeniDurum,
    });
  }

  // --- ÇIKIŞ YAP ---
  Future<void> cikisYap() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Çıkış hatası: $e");
    }
  }

  // --- ŞİFRE DEĞİŞTİR ---
  Future<String?> sifreDegistir(String mevcutSifre, String yeniSifre) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Güvenlik gereği şifre değiştirmeden önce kullanıcıyı yeniden doğruluyoruz (Re-authenticate)
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: mevcutSifre,
        );
        await user.reauthenticateWithCredential(credential);

        // Doğrulama başarılıysa yeni şifreyi ayarla
        await user.updatePassword(yeniSifre);
        return "Başarılı";
      }
      return "Kullanıcı bulunamadı.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return "Mevcut şifrenizi yanlış girdiniz.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // --- HESABI SİL ---
  Future<String?> hesabiSil(String sifre) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        String uid = user.uid;

        // 1. Önce şifre ile yeniden doğrulama yap (Firebase hassas işlemler için bunu zorunlu tutar)
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: sifre,
        );
        await user.reauthenticateWithCredential(credential);

        // 2. Kullanıcının Firestore'daki tüm görevlerini (Tasks) bul ve sil
        final gorevlerSnapshot = await _firestore
            .collection("Tasks")
            .where("userId", isEqualTo: uid)
            .get();

        for (DocumentSnapshot doc in gorevlerSnapshot.docs) {
          await doc.reference.delete();
        }

        // 3. Kullanıcının profil bilgilerini (Users) sil
        await _firestore.collection("Users").doc(uid).delete();

        // 4. Son olarak Authentication (Giriş) sisteminden kullanıcıyı tamamen sil
        await user.delete();

        return "Başarılı";
      }
      return "Kullanıcı bulunamadı.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return "Şifrenizi yanlış girdiniz. Hesap silinemedi.";
      }
      return e.message;
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  // --- KULLANICI ADI GETİR ---
  Future<String?> kullaniciAdiniGetir() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('Users').doc(user.uid).get();
    return doc.data()?['ad'] as String?;
  }

  // --- AVATAR GETİR ---
  Future<String?> avatarIdGetir() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('Users').doc(uid).get();
      return doc.data()?['avatarId'];
    } catch (e) {
      return null;
    }
  }

  // --- AVATAR GÜNCELLE ---
  Future<String?> avatarGuncelle(String yeniAvatarId) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('Users').doc(uid).update({
        'avatarId': yeniAvatarId,
      });
      return "Başarılı";
    } catch (e) {
      return e.toString();
    }
  }

  // --- TEMA GÜNCELLE ---
  Future<void> temaGuncelle(String kategori, String temaId) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('Users').doc(uid).update({
        'temaKategori': kategori.isEmpty ? null : kategori,
        'temaId': temaId.isEmpty ? null : temaId,
      });
    } catch (e) {
      print("Tema güncelleme hatası: $e");
    }
  }

  // --- TEMA GETİR ---
  Future<Map<String, String?>> temaGetir() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('Users').doc(uid).get();
      return {
        'temaKategori': doc.data()?['temaKategori'],
        'temaId': doc.data()?['temaId'],
      };
    } catch (e) {
      return {'temaKategori': null, 'temaId': null};
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  ANALİZ FONKSİYONLARI
  // ─────────────────────────────────────────────────────────────

  static const Map<String, int> _zorlukPuanlari = {
    'kolay': 1,
    'orta': 3,
    'zor': 5,
  };

  static const List<String> _aylar = [
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

  // Verilen tarih aralığındaki tüm görevleri getirir
  Future<List<Map<String, dynamic>>> _tarihAraligiGorevler(
    DateTime baslangic,
    DateTime bitis,
  ) async {
    final uid = _auth.currentUser!.uid;
    final List<Map<String, dynamic>> sonuc = [];

    // Aralıktaki her gün için sorgu at
    DateTime gun = baslangic;
    while (!gun.isAfter(bitis)) {
      final tarihAnahtari = "${gun.day} ${_aylar[gun.month - 1]}";
      final snapshot = await _firestore
          .collection("Tasks")
          .where("userId", isEqualTo: uid)
          .where("tarih", isEqualTo: tarihAnahtari)
          .get();

      for (final doc in snapshot.docs) {
        sonuc.add({...doc.data(), 'gunSirasi': gun.weekday});
      }
      gun = gun.add(const Duration(days: 1));
    }
    return sonuc;
  }

  // --- HAFTALIK ANALİZ ---
  // Döndürdüğü map:
  // {
  //   'gunlukPuanlar': {'Pzt':5, 'Sal':0, ...},   // tamamlanan görev puanları
  //   'toplamPuan': 12,
  //   'toplamGorev': 8,
  //   'tamamlanan': 5,
  //   'kolay': 3, 'orta': 2, 'zor': 0,            // tamamlanan görev zorluk dağılımı
  //   'enVerimliGun': 'Salı',
  // }
  Future<Map<String, dynamic>> haftalikAnalizGetir() async {
    final simdi = DateTime.now();
    final haftaBaslangic = simdi.subtract(Duration(days: simdi.weekday - 1));
    final haftaBitis = haftaBaslangic.add(const Duration(days: 6));

    final gorevler = await _tarihAraligiGorevler(haftaBaslangic, haftaBitis);

    const gunIsimleri = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final gunlukPuanlar = {for (final g in gunIsimleri) g: 0};
    int toplamPuan = 0, tamamlanan = 0, kolay = 0, orta = 0, zor = 0;

    for (final g in gorevler) {
      if (g['tamamlandi'] == true) {
        final zorluk = g['zorluk'] ?? 'kolay';
        final puan = _zorlukPuanlari[zorluk] ?? 1;
        final gunIdx = (g['gunSirasi'] as int) - 1; // 1=Pzt → 0
        gunlukPuanlar[gunIsimleri[gunIdx]] =
            (gunlukPuanlar[gunIsimleri[gunIdx]] ?? 0) + puan;
        toplamPuan += puan;
        tamamlanan++;
        if (zorluk == 'kolay')
          kolay++;
        else if (zorluk == 'orta')
          orta++;
        else if (zorluk == 'zor')
          zor++;
      }
    }

    // En verimli gün
    String enVerimliGun = '-';
    int maxPuan = 0;
    gunlukPuanlar.forEach((gun, puan) {
      if (puan > maxPuan) {
        maxPuan = puan;
        enVerimliGun = gun;
      }
    });

    return {
      'gunlukPuanlar': gunlukPuanlar,
      'toplamPuan': toplamPuan,
      'toplamGorev': gorevler.length,
      'tamamlanan': tamamlanan,
      'kolay': kolay,
      'orta': orta,
      'zor': zor,
      'enVerimliGun': enVerimliGun,
    };
  }

  // --- AYLIK ANALİZ ---
  // Döndürdüğü map:
  // {
  //   'haftalikPuanlar': {'1.Hafta':8, '2.Hafta':15, ...},
  //   'toplamPuan': 40,
  //   'toplamGorev': 20,
  //   'tamamlanan': 14,
  //   'tamamlanmaOrani': 70.0,
  //   'kolay': 5, 'orta': 6, 'zor': 3,
  //   'enVerimliHafta': '2.Hafta',
  // }
  Future<Map<String, dynamic>> aylikAnalizGetir(int yil, int ay) async {
    final ayBaslangic = DateTime(yil, ay, 1);
    final ayBitis = DateTime(yil, ay + 1, 0); // ayın son günü

    final gorevler = await _tarihAraligiGorevler(ayBaslangic, ayBitis);

    // Haftaları böl (1-7, 8-14, 15-21, 22-son)
    final haftaEtiketleri = ['1.Hafta', '2.Hafta', '3.Hafta', '4.Hafta'];
    final haftalikPuanlar = {for (final h in haftaEtiketleri) h: 0};
    int toplamPuan = 0, tamamlanan = 0, kolay = 0, orta = 0, zor = 0;

    for (final g in gorevler) {
      if (g['tamamlandi'] == true) {
        final zorluk = g['zorluk'] ?? 'kolay';
        final puan = _zorlukPuanlari[zorluk] ?? 1;
        toplamPuan += puan;
        tamamlanan++;
        if (zorluk == 'kolay')
          kolay++;
        else if (zorluk == 'orta')
          orta++;
        else if (zorluk == 'zor')
          zor++;
      }
    }

    // Haftaları hesapla — görev tarihine göre
    final uid = _auth.currentUser!.uid;
    for (int hafta = 0; hafta < 4; hafta++) {
      final baslangicGun = hafta * 7 + 1;
      final bitisGun = hafta == 3 ? ayBitis.day : (hafta + 1) * 7;
      int haftaPuani = 0;

      for (int gun = baslangicGun; gun <= bitisGun; gun++) {
        final tarihAnahtari = "$gun ${_aylar[ay - 1]}";
        final snapshot = await _firestore
            .collection("Tasks")
            .where("userId", isEqualTo: uid)
            .where("tarih", isEqualTo: tarihAnahtari)
            .where("tamamlandi", isEqualTo: true)
            .get();

        for (final doc in snapshot.docs) {
          final zorluk = doc.data()['zorluk'] ?? 'kolay';
          haftaPuani += _zorlukPuanlari[zorluk] ?? 1;
        }
      }
      haftalikPuanlar[haftaEtiketleri[hafta]] = haftaPuani;
    }

    // En verimli hafta
    String enVerimliHafta = '-';
    int maxPuan = 0;
    haftalikPuanlar.forEach((hafta, puan) {
      if (puan > maxPuan) {
        maxPuan = puan;
        enVerimliHafta = hafta;
      }
    });

    final tamamlanmaOrani = gorevler.isEmpty
        ? 0.0
        : (tamamlanan / gorevler.length * 100);

    return {
      'haftalikPuanlar': haftalikPuanlar,
      'toplamPuan': toplamPuan,
      'toplamGorev': gorevler.length,
      'tamamlanan': tamamlanan,
      'tamamlanmaOrani': tamamlanmaOrani,
      'kolay': kolay,
      'orta': orta,
      'zor': zor,
      'enVerimliHafta': enVerimliHafta,
    };
  }

  // Eski haftalikPuanGetir — geriye dönük uyumluluk için bırakıldı
  Future<Map<String, int>> haftalikPuanGetir() async {
    final analiz = await haftalikAnalizGetir();
    return Map<String, int>.from(analiz['gunlukPuanlar']);
  }
}
