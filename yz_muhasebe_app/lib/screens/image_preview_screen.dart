import 'package:flutter/material.dart';
import 'dart:io';
import 'validation_screen.dart';

/// Fotoğraf çekildikten sonra gösterilen önizleme ekranı
/// Kullanıcı burada fotoğrafı döndürebilir
class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  int _rotationAngle = 0; // Fotoğraf döndürme açısı (0, 90, 180, 270)

  // Fotoğrafı döndür
  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  // Fotoğrafı onayla ve ValidationScreen'e git
  void _confirmImage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ValidationScreen(
          imagePath: widget.imagePath,
          rotationAngle: _rotationAngle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotoğraf Önizleme'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: 'İptal',
        ),
      ),
      body: Column(
        children: [
          // Fotoğraf Önizleme Alanı
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: _rotationAngle * 3.14159 / 180,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Alt Butonlar
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Döndürme Butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: _rotateImage,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.rotate_right,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Döndür',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                // Tamam Butonu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: _confirmImage,
                      backgroundColor: Colors.green,
                      icon: const Icon(Icons.check, size: 32),
                      label: const Text(
                        'Tamam',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Devam Et',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
