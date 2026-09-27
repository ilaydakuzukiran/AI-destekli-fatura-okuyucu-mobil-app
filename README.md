# 📄 AI Destekli Fatura Analiz ve Yönetim Sistemi

Bu proje, karmaşık yerleşimlere sahip fatura belgelerinden "Fatura No, Tarih ve Toplam Tutar" gibi kritik bilgileri otonom olarak çıkaran ve kullanıcıya özel olarak bulut veritabanında güvenle saklayan uçtan uca bir mobil uygulamadır.

## 🚀 Projenin Amacı ve Çözdüğü Problem
Geleneksel kural tabanlı sistemler veya doğrudan tüm belgeye uygulanan OCR (Optik Karakter Tanıma) işlemleri; fatura üzerindeki logolar, şirket unvanları ve vergi daireleri gibi gürültülü veriler nedeniyle düşük doğruluk oranlarına sahiptir. 

Bu proje, yapay zeka destekli **iki aşamalı bir pipeline (boru hattı)** kullanarak bu sorunu çözer:
1. **Hedef Tespiti:** YOLOv8 modeli, faturadaki metni okumak yerine yalnızca hedeflenen verilerin (tarih, tutar, fatura no) tam konumunu (bounding-box) milisaniyeler içinde tespit eder.
2. **Kırpma ve Çıkarım:** Tespit edilen bu koordinatlar kırpılarak (crop) sadece ilgili küçük alanlar OCR motoruna beslenir. Böylece gürültü sıfıra indirilerek okuma doğruluğu maksimize edilir.

## 🛠️ Kullanılan Teknolojiler
* **Yapay Zeka & Görüntü İşleme:** YOLOv8 (Ultralytics), OpenCV, OCR Motoru
* **Veri Etiketleme:** CVAT
* **Backend / Scripting:** Python
* **Frontend (Mobil Uygulama):** Flutter / Dart
* **Veritabanı & Kimlik Doğrulama:** Firebase Authentication & Cloud Firestore

## ⚙️ Sistem Mimarisi
* **Kullanıcı Yönetimi:** Firebase Auth ile güvenli giriş ve oturum yönetimi.
* **Veri Saklama:** Çıkarılan fatura detaylarının Cloud Firestore üzerinde doküman tabanlı hiyerarşiyle saklanması.
* **Model Eğitimi:** Kendi oluşturduğum veri seti CVAT ile etiketlenmiş, %80 eğitim ve %20 doğrulama (val) formatına uygun olarak YOLOv8 ile eğitilmiştir.

## 📞 Geliştirici
**İlayda Kuzukıran**
