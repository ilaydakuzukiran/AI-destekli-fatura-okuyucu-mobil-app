import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yz_muhasebe_app/models/invoice_data.dart';

class AIService {
  // ---------------------------------------------------------------------------
  // DİKKAT: IPv4 ADRESİNİ BURAYA YAZACAKSIN!
  // Bilgisayarındaki cmd -> ipconfig çıktısındaki IPv4 adresini buraya yapıştır.
  // Port numarası (:5000) sabit kalsın.
  // Örnek: 'http://192.168.1.35:5000/predict';
  // ---------------------------------------------------------------------------
  static const String _baseUrl = 'http://172.20.10.2:5000/predict';

  Future<InvoiceData> extractInvoiceData(String imagePath) async {
    try {
      final File imageFile = File(imagePath);

      // 1. Resmi Base64 formatına çevir (Sunucuya göndermek için)
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      debugPrint("Sunucuya istek gönderiliyor: $_baseUrl");

      // 2. Python Sunucusuna Gönder
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "image": base64Image,
            }),
          )
          .timeout(const Duration(seconds: 15)); // 15 saniye zaman aşımı

      if (response.statusCode == 200) {
        // 3. Sunucudan gelen cevabı al
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint("Sunucudan cevap geldi: $responseData");

        // Gelen veriyi senin InvoiceData modeline çevir
        return InvoiceData.fromJson(responseData, imagePath);
      } else {
        debugPrint("Sunucu Hatası: ${response.statusCode}");
        debugPrint("Hata Mesajı: ${response.body}");

        // Hata durumunda sadece resim yolu olan boş bir nesne dön
        return InvoiceData(imagePath: imagePath, saticiAdi: "Sunucu Hatası");
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return InvoiceData(imagePath: imagePath, saticiAdi: "Bağlantı Hatası");
    }
  }
}
