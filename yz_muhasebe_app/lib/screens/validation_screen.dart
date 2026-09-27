import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yz_muhasebe_app/models/invoice_data.dart';
import 'package:yz_muhasebe_app/services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ValidationScreen extends StatefulWidget {
  final String imagePath;
  final int rotationAngle;

  const ValidationScreen({
    super.key,
    required this.imagePath,
    this.rotationAngle = 0,
  });

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  // Veritabanı referansı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // YZ'den gelen veriyi tutacak model ve form key
  late InvoiceData _extractedData;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _processInvoice(); // Ekran açıldığında faturayı işlemeye başla
  }

  // Kamera iznini kontrol et ve al
  Future<bool> _requestCameraPermission() async {
    // Mevcut izin durumunu kontrol et
    PermissionStatus status = await Permission.camera.status;

    // Debug için izin durumunu yazdır (sadece debug modunda)
    if (kDebugMode) debugPrint('Kamera izin durumu: $status');

    // Eğer izin verilmemişse, iste
    if (!status.isGranted) {
      // İzin iste
      status = await Permission.camera.request();
      if (kDebugMode) debugPrint('İzin istendi, yeni durum: $status');
    }

    if (status.isPermanentlyDenied) {
      // Kalıcı olarak reddedildiyse, ayarları aç
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kamera İzni Gerekli'),
            content: const Text(
                'Kamera kullanmak için uygulama ayarlarından kamera iznini açmanız gerekiyor.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni reddedildi!')),
        );
      }
      return false;
    }

    return status.isGranted;
  }

  // Kamerayı aç ve fotoğraf çek
  Future<void> _takePicture() async {
    final hasPermission = await _requestCameraPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni verilmedi!')),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _isLoading = true;
        });

        // Yeni fotoğrafı işle
        final AIService aiService = AIService();
        final InvoiceData result =
            await aiService.extractInvoiceData(photo.path);

        setState(() {
          _extractedData = result;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni fatura başarıyla yüklendi!')),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Kamera Hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera açılırken hata oluştu!')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // YZ servisini çağırma ve veriyi çekme
  Future<void> _processInvoice() async {
    try {
      final AIService aiService = AIService();
      final InvoiceData result =
          await aiService.extractInvoiceData(widget.imagePath);

      setState(() {
        _extractedData = result;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('İşleme Hatası: $e');
      setState(() {
        _isLoading = false;
        // Hata durumunda boş model ile devam et
        _extractedData =
            InvoiceData(imagePath: widget.imagePath, saticiAdi: 'HATA');
      });
    }
  }

  // Veriyi Firestore'a kaydetme
  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Form verilerini modelimize kaydet

      try {
        // Kullanıcı bazlı kayıt: users/{userId}/invoices
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('Kullanıcı oturumu bulunamadı');
        }

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .add(_extractedData.toFirestore());

        // Başarılı bildirim ve ana sayfaya dönme
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fatura başarıyla kaydedildi!')),
          );
          // Ana ekrana dönmek için tüm stack'i temizle
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Firestore Kayıt Hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt sırasında hata oluştu: $e')),
          );
        }
      }
    }
  }

  // Form elemanı oluşturucu (tekrar eden kodu azaltmak için)
  Widget _buildTextField(
      String label, String? initialValue, Function(String?) onSaved) {
    return TextFormField(
      initialValue: initialValue ?? '',
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onSaved: onSaved,
      validator: (value) =>
          value!.isEmpty ? '$label alanı boş bırakılamaz.' : null,
      keyboardType:
          label.contains('Tutar') ? TextInputType.number : TextInputType.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Onay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Yeni Fotoğraf Çek',
            onPressed: _takePicture,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Fatura Görseli Önizlemesi
                  Transform.rotate(
                    angle: widget.rotationAngle * 3.14159 / 180,
                    child: Image.file(
                      File(_extractedData.imagePath),
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Doğrulama Formu
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          'İş Yeri Adı',
                          _extractedData.saticiAdi,
                          (newValue) => _extractedData =
                              _extractedData.copyWith(saticiAdi: newValue),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          'Fatura Tarihi (DD-MM-YYYY)',
                          _extractedData.faturaTarihi,
                          (newValue) => _extractedData =
                              _extractedData.copyWith(faturaTarihi: newValue),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          'Toplam Tutar',
                          _extractedData.toplamTutar?.toString(),
                          (newValue) => _extractedData =
                              _extractedData.copyWith(
                                  toplamTutar:
                                      double.tryParse(newValue ?? '0')),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveInvoice,
                          child: const Text('Veriyi Onayla ve Kaydet'),
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
