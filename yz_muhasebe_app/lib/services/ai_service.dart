import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yz_muhasebe_app/models/invoice_data.dart';

class AIService {
  static const String _baseUrl = '*IPV4 ADRESİ BURAYA YAZILACAK, PORT:5000 KALABİLİR*';

  Future<InvoiceData> extractInvoiceData(String imagePath) async {
    try {
      final File imageFile = File(imagePath);

      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      debugPrint("Sunucuya istek gönderiliyor: $_baseUrl");

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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint("Sunucudan cevap geldi: $responseData");

        return InvoiceData.fromJson(responseData, imagePath);
      } else {
        debugPrint("Sunucu Hatası: ${response.statusCode}");
        debugPrint("Hata Mesajı: ${response.body}");

        return InvoiceData(imagePath: imagePath, saticiAdi: "Sunucu Hatası");
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return InvoiceData(imagePath: imagePath, saticiAdi: "Bağlantı Hatası");
    }
  }
}
