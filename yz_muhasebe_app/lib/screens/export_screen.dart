// lib/screens/export_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _ipController = TextEditingController();
  String _localIp = 'IP Adresi Alınıyor...';
  final int _port = 8000; // Python betiği ile aynı port (C.2.2'de belirlendi)

  // Tarih seçimi için
  DateTime? _startDate;
  DateTime? _endDate;

  // Bağlantı yeniden deneme için
  int _retryCount = 0;
  final int _maxRetries = 3;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _getWifiIP(); // Mobil cihazın IP'sini al
  }

  // Mobil cihazın yerel ağ IP adresini alır
  Future<void> _getWifiIP() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();
    setState(() {
      _localIp = wifiIP ?? 'IP Alınamadı';
    });
  }

  // Tarih seçici göster
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: isStartDate ? 'Başlangıç Tarihi Seçin' : 'Bitiş Tarihi Seçin',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Eğer bitiş tarihi başlangıçtan önce ise güncelle
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Eğer başlangıç tarihi bitişten sonra ise güncelle
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  // Format tarihi DD-MM-YYYY formatına
  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih Seçin';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Veriyi Firestore'dan Çekme ve PC'ye Gönderme (6. Hafta Planı)
  Future<void> _exportData() async {
    if (_isExporting) return; // Çift tıklama önleme

    if (_ipController.text.isEmpty) {
      _showSnackBar('Lütfen PC IP adresini girin.');
      return;
    }

    // Tarih kontrolü
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Lütfen başlangıç ve bitiş tarihini seçin.');
      return;
    }

    setState(() {
      _isExporting = true;
      _retryCount = 0;
    });

    final String pcIp = _ipController.text;
    _showSnackBar('Veriler çekiliyor...', duration: 2);

    try {
      // Kullanıcı ID'sini al
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _showSnackBar('Kullanıcı oturumu bulunamadı');
        setState(() => _isExporting = false);
        return;
      }

      // 1. Veriyi Firestore'dan Çekme (Tüm faturaları çek, sonra filtrele)
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firestore sorgusu zaman aşımına uğradı');
        },
      );

      // Client-side tarih filtreleme (DD-MM-YYYY formatı için)
      final List<Map<String, dynamic>> allData = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      debugPrint('📊 Toplam fatura sayısı: ${allData.length}');
      debugPrint('📅 Seçilen başlangıç: ${_formatDate(_startDate)}');
      debugPrint('📅 Seçilen bitiş: ${_formatDate(_endDate)}');

      final List<Map<String, dynamic>> dataToExport = allData.where((invoice) {
        final String? faturaTarihi = invoice['faturaTarihi'] as String?;
        if (faturaTarihi == null) {
          debugPrint('⚠️ Tarih null olan fatura atlandı');
          return false;
        }

        try {
          // DD-MM-YYYY formatını DateTime'a çevir
          final parts = faturaTarihi.split('-');
          if (parts.length != 3) {
            debugPrint('⚠️ Geçersiz tarih formatı: $faturaTarihi');
            return false;
          }

          final invoiceDate = DateTime(
            int.parse(parts[2]), // Yıl
            int.parse(parts[1]), // Ay
            int.parse(parts[0]), // Gün
          );

          // Seçilen tarih aralığında mı kontrol et
          final startOfDay =
              DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final endOfDay = DateTime(
              _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

          final isInRange = invoiceDate
                  .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              invoiceDate.isBefore(endOfDay.add(const Duration(seconds: 1)));

          debugPrint(
              '🔍 Fatura: $faturaTarihi → ${isInRange ? "✅ DAHİL" : "❌ HARİÇ"}');

          return isInRange;
        } catch (e) {
          debugPrint('❌ Tarih parse hatası: $faturaTarihi - $e');
          return false;
        }
      }).toList();

      debugPrint('✅ Filtrelenmiş fatura sayısı: ${dataToExport.length}');

      if (dataToExport.isEmpty) {
        _showSnackBar('Belirtilen tarihler arasında fatura bulunamadı.');
        setState(() => _isExporting = false);
        return;
      }

      // 2. P2P Bağlantı ile veri gönderme (retry mekanizması ile)
      await _sendDataWithRetry(pcIp, dataToExport);
    } on TimeoutException catch (e) {
      _showSnackBar('⏱️ Zaman Aşımı: ${e.message}');
      setState(() => _isExporting = false);
    } on SocketException catch (e) {
      _showSnackBar('❌ Bağlantı Hatası: Ağ bağlantısını kontrol edin');
      debugPrint('SocketException: $e');
      setState(() => _isExporting = false);
    } catch (e) {
      _showSnackBar('❌ Hata: $e');
      debugPrint('Export error: $e');
      setState(() => _isExporting = false);
    }
  }

  // Yeniden deneme mekanizması ile veri gönderme
  Future<void> _sendDataWithRetry(
      String pcIp, List<Map<String, dynamic>> data) async {
    while (_retryCount <= _maxRetries) {
      try {
        debugPrint('🔌 Bağlantı denemesi: $pcIp:$_port (Deneme: $_retryCount)');
        _showSnackBar(
          _retryCount == 0
              ? 'PC\'ye bağlanılıyor: $pcIp:$_port'
              : 'Yeniden deneniyor... ($_retryCount/$_maxRetries)',
          duration: 2,
        );

        // Socket bağlantısı kur (timeout ile)
        debugPrint('⏳ Socket.connect başlatılıyor...');
        final Socket socket = await Socket.connect(
          pcIp,
          _port,
          timeout: const Duration(seconds: 8),
        );
        debugPrint(
            '✅ Bağlantı başarılı! ${socket.remoteAddress}:${socket.remotePort}');

        // JSON verisini gönder
        debugPrint('📤 JSON verisi gönderiliyor... (${data.length} fatura)');
        final String jsonString = jsonEncode(data);
        socket.write(jsonString);
        await socket.flush().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('❌ Veri gönderimi timeout!');
            throw TimeoutException('Veri gönderimi zaman aşımına uğradı');
          },
        );
        debugPrint('✅ Veri gönderimi tamamlandı');

        // Başarılı gönderim sonrası socket'i kapat
        await socket.close();

        _showSnackBar(
          '✅ Başarılı! ${data.length} fatura PC\'ye aktarıldı.\nPython sunucusunu kontrol edin.',
          duration: 5,
        );

        setState(() => _isExporting = false);
        return; // Başarılı, fonksiyondan çık
      } on SocketException catch (e) {
        _retryCount++;
        debugPrint('❌ SocketException: $e');
        debugPrint('📍 Adres: $pcIp:$_port, Deneme: $_retryCount/$_maxRetries');

        if (_retryCount > _maxRetries) {
          // Son deneme de başarısız oldu
          debugPrint('💀 Tüm denemeler başarısız oldu');
          _showSnackBar(
            '❌ Bağlantı Kurulamadı!\n'
            '• PC IP: $pcIp:$_port\n'
            '• Python sunucusu çalışıyor mu?\n'
            '• Her iki cihazın aynı WiFi ağında olduğunu doğrulayın\n'
            '• Port: $_port',
            duration: 8,
          );
          setState(() => _isExporting = false);
          return;
        }

        // Bir sonraki deneme öncesi bekle
        await Future.delayed(Duration(seconds: _retryCount * 2));
      } on TimeoutException catch (e) {
        _retryCount++;

        if (_retryCount > _maxRetries) {
          _showSnackBar(
            '⏱️ Zaman Aşımı!\n${e.message}\n'
            'Python sunucusu yanıt vermiyor olabilir.',
            duration: 6,
          );
          setState(() => _isExporting = false);
          return;
        }

        await Future.delayed(Duration(seconds: _retryCount * 2));
      }
    }
  }

  void _showSnackBar(String message, {int duration = 3}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: duration)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veri Aktarımı ve Excel Çıktısı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aktarım Bilgileri:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Mobil Cihaz IP\'niz: $_localIp (Aynı ağda olmalı)'),
            Text('Aktarım Portu: $_port'),
            const SizedBox(height: 20),

            // PC IP Adresi Girişi
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Hedef PC IP Adresi',
                hintText: 'Örn: 192.168.1.10',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // Tarih Aralığı Seçimi
            const Text('Aktarılacak Fatura Tarih Aralığı:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Başlangıç Tarihi Seçici
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Başlangıç Tarihi',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(_startDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Bitiş Tarihi Seçici
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bitiş Tarihi',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(_endDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _endDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Colors.blue, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Aktarım Butonu
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isExporting
                  ? 'Aktarılıyor...'
                  : 'Veriyi PC\'ye Aktar ve Excel Oluştur'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            // Yardım Metni
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bağlantı Gereksinimleri',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Her iki cihaz aynı WiFi ağında olmalı\n'
                    '• PC\'de Python sunucusu çalışıyor olmalı\n'
                    '• Python komutu: python excel_transfer_receiver.py\n'
                    '• Bağlantı 3 kez otomatik yeniden denenecek',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
