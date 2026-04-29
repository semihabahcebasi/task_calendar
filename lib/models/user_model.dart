class UserModel {
  final String uid;
  final String email;
  final String ad;
  final String soyad;
  final String avatarId;

  UserModel({
    required this.uid,
    required this.email,
    required this.ad,
    required this.soyad,
    required this.avatarId,
  });

  // Firestore'dan gelen veriyi UserModel'e çevirir
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      avatarId: map['avatarId'] ?? 'avatar_1',
    );
  }

  // UserModel'i Firestore'a göndermek için Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'ad': ad,
      'soyad': soyad,
      'avatarId': avatarId,
    };
  }
}
