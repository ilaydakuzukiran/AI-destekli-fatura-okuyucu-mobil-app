class InvoiceData {
  // YZ prompt'u ve JSON çıktısı ile uyumlu olarak Türkçe karakter içermeyen adlar
  final String? saticiAdi;
  final String? faturaTarihi; // DD-MM-YYYY formatında
  final double? toplamTutar;
  final String imagePath; // Mobil cihazda çekilen fotoğrafın yolu

  InvoiceData({
    required this.imagePath,
    this.saticiAdi,
    this.faturaTarihi,
    this.toplamTutar,
  });

  // YZ'den gelen JSON'u bu nesneye dönüştürmek için Factory Constructor
  factory InvoiceData.fromJson(Map<String, dynamic> json, String path) {
    return InvoiceData(
      imagePath: path,
      // JSON anahtarları model eğitiminde kullanılan İngilizce etiketlerle eşleştirildi
      // Model etiketleri: 0=date, 1=price, 2=workplace
      // Her iki format da destekleniyor (Türkçe ve İngilizce)
      saticiAdi: (json['workplace'] ?? json['saticiAdi']) as String?,
      faturaTarihi: (json['date'] ?? json['faturaTarihi']) as String?,
      // Tutar alanı işlenirken, JSON'dan gelen stringin double'a çevrilmesi
      toplamTutar: double.tryParse((json['price'] ?? json['toplamTutar'])
          .toString()
          .replaceAll(',', '.')),
    );
  }

  // Firestore'a kaydetmek veya Excel'e aktarmak için Map'e dönüştürme metodu
  Map<String, dynamic> toFirestore() {
    return {
      'saticiAdi': saticiAdi,
      'faturaTarihi': faturaTarihi,
      'toplamTutar': toplamTutar,
      'kayitTarihi': DateTime.now().toIso8601String(), // Kayıt zaman damgası
    };
  }

  // Formdaki veriyi değiştirmek için (ValidationScreen'da kullanıldı)
  InvoiceData copyWith({
    String? saticiAdi,
    String? faturaTarihi,
    double? toplamTutar,
    String? imagePath,
  }) {
    return InvoiceData(
      imagePath: imagePath ?? this.imagePath,
      saticiAdi: saticiAdi ?? this.saticiAdi,
      faturaTarihi: faturaTarihi ?? this.faturaTarihi,
      toplamTutar: toplamTutar ?? this.toplamTutar,
    );
  }
}
