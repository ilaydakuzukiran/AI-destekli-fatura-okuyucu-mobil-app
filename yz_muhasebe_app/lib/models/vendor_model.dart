import 'package:cloud_firestore/cloud_firestore.dart';

/// Satıcı/Tedarikçi model sınıfı
/// Firestore koleksiyonu: vendors (global) veya users/{userId}/vendors (kullanıcı bazlı)
class Vendor {
  final String? id; // Firestore document ID
  final String userId; // Satıcıyı oluşturan kullanıcı
  final String name; // Satıcı adı/unvanı
  final String? taxNumber; // Vergi numarası
  final String? taxOffice; // Vergi dairesi
  final String? address; // Adres
  final String? city; // Şehir
  final String? country; // Ülke
  final String? phone; // Telefon
  final String? email; // E-posta
  final String? website; // Web sitesi
  final String? contactPerson; // İrtibat kişisi
  final String category; // Kategori: 'supplier', 'service', 'other'
  final bool isActive; // Aktif/Pasif durum
  final DateTime createdAt; // Kayıt tarihi
  final DateTime? updatedAt; // Güncellenme tarihi
  final int invoiceCount; // Bu satıcıdan kaç fatura var
  final double totalAmount; // Bu satıcıdan toplam fatura tutarı

  Vendor({
    this.id,
    required this.userId,
    required this.name,
    this.taxNumber,
    this.taxOffice,
    this.address,
    this.city,
    this.country = 'Türkiye',
    this.phone,
    this.email,
    this.website,
    this.contactPerson,
    this.category = 'supplier',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.invoiceCount = 0,
    this.totalAmount = 0.0,
  });

  /// Firestore'dan Vendor oluştur
  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      taxNumber: data['taxNumber'] as String?,
      taxOffice: data['taxOffice'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String? ?? 'Türkiye',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      contactPerson: data['contactPerson'] as String?,
      category: data['category'] as String? ?? 'supplier',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      invoiceCount: data['invoiceCount'] as int? ?? 0,
      totalAmount: data['totalAmount'] != null
          ? (data['totalAmount'] as num).toDouble()
          : 0.0,
    );
  }

  /// Firestore'dan Vendor oluştur (Map'ten)
  factory Vendor.fromMap(Map<String, dynamic> data, String id) {
    return Vendor(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      taxNumber: data['taxNumber'] as String?,
      taxOffice: data['taxOffice'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String? ?? 'Türkiye',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      contactPerson: data['contactPerson'] as String?,
      category: data['category'] as String? ?? 'supplier',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      invoiceCount: data['invoiceCount'] as int? ?? 0,
      totalAmount: data['totalAmount'] != null
          ? (data['totalAmount'] as num).toDouble()
          : 0.0,
    );
  }

  /// Basit satıcı oluştur (sadece isim ile)
  factory Vendor.simple({
    required String userId,
    required String name,
  }) {
    return Vendor(
      userId: userId,
      name: name,
      createdAt: DateTime.now(),
    );
  }

  /// Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'taxNumber': taxNumber,
      'taxOffice': taxOffice,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'contactPerson': contactPerson,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'invoiceCount': invoiceCount,
      'totalAmount': totalAmount,
    };
  }

  /// Satıcı bilgilerini güncellemek için copyWith
  Vendor copyWith({
    String? id,
    String? userId,
    String? name,
    String? taxNumber,
    String? taxOffice,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? contactPerson,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? invoiceCount,
    double? totalAmount,
  }) {
    return Vendor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      taxNumber: taxNumber ?? this.taxNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      contactPerson: contactPerson ?? this.contactPerson,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  String toString() {
    return 'Vendor(id: $id, name: $name, taxNumber: $taxNumber, invoiceCount: $invoiceCount)';
  }

  /// İstatistikler için özet bilgi
  String getSummary() {
    return '$name - $invoiceCount fatura (₺${totalAmount.toStringAsFixed(2)})';
  }
}
