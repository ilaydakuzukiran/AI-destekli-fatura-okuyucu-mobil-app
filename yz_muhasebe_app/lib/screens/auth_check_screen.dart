import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yz_muhasebe_app/screens/home_screen.dart'; // HomeScreen'a erişmek için
import 'login_screen.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth.instance.authStateChanges() akışını dinler.
    // Kullanıcının oturum durumu değiştiğinde (giriş/çıkış) otomatik güncellenir.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Eğer bağlantı bekleniyorsa (kontrol ediliyor) bir yükleme göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Eğer veride bir kullanıcı varsa (Giriş Yapmış)
        if (snapshot.hasData) {
          // HomeScreen'a yönlendir
          return const HomeScreen();
        }

        // Eğer kullanıcı yoksa (Giriş Yapmamış)
        // Login/Register ekranına yönlendir
        return const LoginScreen();
      },
    );
  }
}
