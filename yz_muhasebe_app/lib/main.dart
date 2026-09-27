import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yz_muhasebe_app/screens/validation_screen.dart';
import 'package:yz_muhasebe_app/screens/export_screen.dart';
import 'package:yz_muhasebe_app/screens/auth_check_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // Flutter widget'larının başlatıldığından emin olun (Firebase için zorunlu)
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatma
  await Firebase.initializeApp(
    // Platforma uygun ayarları kullan
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YZ Muhasebe Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Türkçe dil desteği
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        Locale('en', 'US'), // İngilizce
      ],
      locale: const Locale('tr', 'TR'),
      // Uygulamanın başlayacağı ana ekranı AuthCheckScreen olarak tanımlayın
      home: const AuthCheckScreen(),
    );
  }
}

// Yeni oluşturacağınız ekran
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ImagePicker _picker = ImagePicker();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Uygulama açılır açılmaz kamera iznini kontrol et ve kamerayı aç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndOpenCamera();
    });
  }

  // Kamera iznini kontrol et ve kamerayı aç
  Future<void> _checkPermissionAndOpenCamera() async {
    PermissionStatus status = await Permission.camera.status;

    if (!status.isGranted) {
      // İzin verilmemişse, iste
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      // İzin verildiyse, kamerayı aç
      _captureInvoice();
    } else if (status.isPermanentlyDenied) {
      // Kalıcı olarak reddedildiyse, ayarlara yönlendir
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kamera İzni Gerekli'),
            content: const Text(
              'Fatura taraması için kamera iznine ihtiyacımız var. Lütfen ayarlardan kamera iznini açın.',
            ),
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
    } else {
      // İzin reddedildiyse, kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera izni gerekli! Lütfen izin verin.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Firebase oturumunu kapatma fonksiyonu
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Oturum kapatıldıktan sonra AuthCheckScreen otomatik olarak LoginScreen'i gösterecektir.
    } catch (e) {
      // ignore: avoid_print
      print("Çıkış Yapma Hatası: $e");
    }
  }

  // Kamera ile fotoğraf çekme fonksiyonu
  Future<void> _captureInvoice() async {
    try {
      // Kamera kaynağını seçme
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        // Fotoğraf çekildiyse, ValidationScreen'a yönlendir
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ValidationScreen(imagePath: photo.path),
            ),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Kamera Hatası: $e");
      // Kullanıcıya hata mesajı gösterebiliriz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YZ Muhasebe Sistemi'),
        actions: [
          // Çıkış Yap butonu <--- YENİ EKLENTİ
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: const Center(
        child: Text('Yeni fatura taraması için butona basın.'),
      ),
      // İki butonu da içerecek şekilde Column yapısı eklendi
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end, // Butonları sağa hizala
        children: [
          // YENİ BUTON: Veri Aktarımı
          FloatingActionButton.extended(
            heroTag: 'export',
            onPressed: () {
              // ExportScreen'a yönlendirme
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExportScreen()));
            },
            label: const Text('Veri Aktarımı'),
            icon: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 10),

          // MEVCUT BUTON: Fatura Tara
          FloatingActionButton.extended(
            heroTag: 'capture',
            onPressed: _captureInvoice,
            label: const Text('Fatura Tara'),
            icon: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
