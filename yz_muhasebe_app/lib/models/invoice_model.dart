import 'package:cloud_firestore/cloud_firestore.dart';

/// Basitleştirilmiş Fatura model sınıfı
/// Firestore koleksiyonu: users/{userId}/invoices
/// Sadece temel bilgiler: Tarih, Tutar, İş Yeri Adı
class Invoice {
  final String? id; // Firestore document ID
  final String userId; // Faturayı oluşturan kullanıcı
  final String vendorId; // Satıcı ID
  final String vendorName; // İş yeri adı/Satıcı adı
  final String invoiceDate; // Fatura tarihi (DD-MM-YYYY)
  final double totalAmount; // Toplam tutar
  final String? imageUrl; // Firebase Storage'daki fatura görseli URL'si
  final DateTime createdAt; // Kayıt tarihi

  Invoice({
    this.id,
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.invoiceDate,
    required this.totalAmount,
    this.imageUrl,
    required this.createdAt,
  });

  /// Firestore'dan Invoice oluştur
  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      userId: data['userId'] as String,
      vendorId: data['vendorId'] as String,
      vendorName: data['vendorName'] as String,
      invoiceDate: data['invoiceDate'] as String,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore'dan Invoice oluştur (Map'ten)
  factory Invoice.fromMap(Map<String, dynamic> data, String id) {
    return Invoice(
      id: id,
      userId: data['userId'] as String,
      vendorId: data['vendorId'] as String,
      vendorName: data['vendorName'] as String,
      invoiceDate: data['invoiceDate'] as String,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Eski InvoiceData modelinden dönüştür (geriye uyumluluk)
  factory Invoice.fromLegacyData({
    required String userId,
    required String vendorId,
    required String vendorName,
    required String invoiceDate,
    required double totalAmount,
    String? imageUrl,
  }) {
    return Invoice(
      userId: userId,
      vendorId: vendorId,
      vendorName: vendorName,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'invoiceDate': invoiceDate,
      'totalAmount': totalAmount,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Excel export için Map
  Map<String, dynamic> toExcelMap() {
    return {
      'faturaTarihi': invoiceDate,
      'saticiAdi': vendorName,
      'toplamTutar': totalAmount,
    };
  }

  /// Geriye uyumluluk için eski format (HomeScreen için)
  Map<String, dynamic> toLegacyMap() {
    return {
      'saticiAdi': vendorName,
      'faturaTarihi': invoiceDate,
      'toplamTutar': totalAmount,
      'kayitTarihi': createdAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? userId,
    String? vendorId,
    String? vendorName,
    String? invoiceDate,
    double? totalAmount,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Invoice(id: $id, vendorName: $vendorName, totalAmount: $totalAmount, date: $invoiceDate)';
  }
}
