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
  // böylece veritabanı işlemlerini gerçekleştirebiliriz

  // Kayıt Olma Fonksiyonu
  Future<String?> kayitOl(
    String email,
    String password,
    String ad,
    String soyad,
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
}
