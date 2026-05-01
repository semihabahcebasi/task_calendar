// bu kısım butonlara basıldığında firebase kaydedilecek olan verileri oluşturduğumuz kısımdır
import 'package:firebase_auth/firebase_auth.dart'; // kimlik doğrulama işlemleri için Firebase Authentication paketini ekliyoruz
import 'package:cloud_firestore/cloud_firestore.dart'; // veritabanı işlemleri için Cloud Firestore paketini ekliyoruz

//Firebase Auth sadece "Giriş yapabilir mi?" sorusuna bakar.
//Firestore ise "Bu kişinin adı ne?" sorusuna yanıt verir.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //instance ile FirebaseAuth sınıfının bir örneğini oluşturuyoruz,
  // böylece kimlik doğrulama işlemlerini gerçekleştirebiliriz
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //instance ile FirebaseFirestore sınıfının bir örneğini oluşturuyoruz,
  // böylece veritabanı işlemlerini gerçekleştirebiliriz.

  // Kayıt Olma Fonksiyonu
  Future<String?> kayitOl(
    String email,
    String password,
    String ad,
    String soyad,
    String
    avatarId, // avatarId parametresi ekledik, böylece kullanıcı kaydolurken avatar seçebilir
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        // yeni bir kullanıcı oluşturmak için createUserWithEmailAndPassword metodunu kullanıyoruz
        email: email,
        password: password,
      );
      User? user = result.user; // oluşturulan kullanıcıyı alıyoruz

      // Kayıt başarılıysa, kullanıcının adını soyadını veritabanına yazalım

      // Firestore'da "Users" koleksiyonuna yeni bir belge ekliyoruz,
      // belgenin ID'si kullanıcı UID'si olacak şekilde ayarlıyoruz
      // yani  users klasörümüz ; uid de her kullanıcıya özel olan klasör içindeki dosya diyebilriz
      await _firestore.collection("Users").doc(user!.uid).set({
        "ad": ad,
        "soyad": soyad,
        "email": email,
        'avatarId': avatarId,
      });
      return "Başarılı";
    } catch (e) {
      return e.toString(); // Hata olursa sebebini döndürür
    }
  }

  // Giriş Yapma Fonksiyonu
  Future<String?> girisYap(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Başarılı";
    } catch (e) {
      return e.toString();
    }
  }

  //home sayfasında görev ekleme ve silme işlemleri için iki fonksiyon daha ekleyelim

  // 1. Görev Ekleme: Kullanıcının ID'sini ve seçilen tarihi baz alarak kayıt yapar
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

  // 2. Görevleri Getirme (Stream): Veritabanı değiştikçe bize yeni listeyi akıtır
  Stream<QuerySnapshot> gorevleriGetir(String tarih) {
    String uid = _auth.currentUser!.uid;

    return _firestore
        .collection("Tasks")
        .where("userId", isEqualTo: uid) // "==" yerine isEqualTo: kullanıyoruz
        .where("tarih", isEqualTo: tarih)
        .orderBy("olusturmaTarihi", descending: true) // En yeni en üstte
        .snapshots(); // Canlı yayın başlasın!
  }

  // 3. Görev Silme: Belgenin benzersiz ID'sini kullanarak siler
  Future<void> gorevSil(String docId) async {
    await _firestore.collection("Tasks").doc(docId).delete();
  }

  // radio butonları için görev durumunu değiştirme fonksiyonu

  Future<void> gorevDurumDegistir(String docId, bool yeniDurum) async {
    await _firestore.collection("Tasks").doc(docId).update({
      "tamamlandi":
          yeniDurum, // Sadece bu alanı güncelliyoruz, diğerleri sabit kalır
    });
  }

  //çıkış yapma fonksiyonu
  Future<void> cikisYap() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Çıkış hatası: $e");
    }
  }

  Future<String?> kullaniciAdiniGetir() async {
    final user = _auth.currentUser; // instance yerine mevcut _auth'u kullan
    if (user == null) return null;

    final doc = await _firestore
        .collection('Users') // ← büyük U, kayıt ile aynı
        .doc(user.uid)
        .get();

    return doc.data()?['ad'] as String?;
  }

  Future<String?> avatarIdGetir() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('Users').doc(uid).get();
      return doc.data()?['avatarId'];
    } catch (e) {
      return null;
    }
  }

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

  // tema güncelleme fonksiyonu: kullanıcı temayı seçtikten sonra bu
  // fonksiyonla Firestore'daki verileri güncelleriz

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

  // HAFTALIK PUAN GETİRME FONKSİYONU: Kullanıcının haftalık performansını göstermek için
  Future<Map<String, int>> haftalikPuanGetir() async {
    String uid = _auth.currentUser!.uid;

    final simdi = DateTime.now();
    final haftaninIlkGunu = simdi.subtract(Duration(days: simdi.weekday - 1));

    Map<String, int> gunlukPuanlar = {
      'Pzt': 0,
      'Sal': 0,
      'Çar': 0,
      'Per': 0,
      'Cum': 0,
      'Cmt': 0,
      'Paz': 0,
    };

    final List<String> gunIsimleri = [
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz',
    ];

    final Map<String, int> zorlukPuanlari = {'kolay': 1, 'orta': 3, 'zor': 5};

    for (int i = 0; i < 7; i++) {
      final gun = haftaninIlkGunu.add(Duration(days: i));
      final aylar = [
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
      final tarihAnahtari = "${gun.day} ${aylar[gun.month - 1]}";

      final snapshot = await _firestore
          .collection("Tasks")
          .where("userId", isEqualTo: uid)
          .where("tarih", isEqualTo: tarihAnahtari)
          .where("tamamlandi", isEqualTo: true)
          .get();

      int gunPuani = 0;
      for (var doc in snapshot.docs) {
        final zorluk = doc.data()['zorluk'] ?? 'kolay';
        gunPuani += zorlukPuanlari[zorluk] ?? 1;
      }
      gunlukPuanlar[gunIsimleri[i]] = gunPuani;
    }

    return gunlukPuanlar;
  }
}
