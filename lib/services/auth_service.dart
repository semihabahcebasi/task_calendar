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
  Future<void> gorevEkle(String baslik, String tarih) async {
    String uid = _auth.currentUser!.uid;

    await _firestore.collection("Tasks").add({
      "userId": uid,
      "baslik": baslik,
      "tarih": tarih,
      "tamamlandi": false,
      "olusturmaTarihi":
          FieldValue.serverTimestamp(), // Görevleri sıraya koymak için
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
}
