import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı model sınıfı
/// Firestore koleksiyonu: users
class UserModel {
  final String uid; // Firebase Auth User ID
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? companyName; // Şirket adı (muhasebe için)
  final String? taxNumber; // Vergi numarası
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String role; // 'user', 'admin', 'accountant' gibi

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.companyName,
    this.taxNumber,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.role = 'user',
  });

  /// Firestore'dan UserModel oluştur
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      companyName: data['companyName'] as String?,
      taxNumber: data['taxNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      role: data['role'] as String? ?? 'user',
    );
  }

  /// Firestore'dan UserModel oluştur (Map'ten)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      companyName: data['companyName'] as String?,
      taxNumber: data['taxNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      role: data['role'] as String? ?? 'user',
    );
  }

  /// Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'companyName': companyName,
      'taxNumber': taxNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'role': role,
    };
  }

  /// Kullanıcı bilgilerini güncellemek için copyWith
  UserModel copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    String? companyName,
    String? taxNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, companyName: $companyName)';
  }
}
