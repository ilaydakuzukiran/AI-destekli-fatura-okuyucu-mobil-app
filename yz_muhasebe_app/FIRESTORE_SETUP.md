# ⚠️ FIRESTORE VERİTABANI KURULUMU GEREKLİ

## 🔴 SORUN
Uygulamayı çalıştırdığınızda şu hatayı alıyorsunuz:

```
Status{code=NOT_FOUND, description=The database (default) does not exist 
for project yz-muhasebe-app
```

## ✅ ÇÖZÜM

Firebase Console'dan Firestore veritabanını aktifleştirmeniz gerekiyor.

### Adım 1: Firebase Console'a Git
1. https://console.firebase.google.com/ adresine git
2. `yz-muhasebe-app` projesini seç

### Adım 2: Firestore'u Aktifleştir
1. Sol menüden **"Build"** > **"Firestore Database"** seçeneğine tıkla
2. **"Create database"** butonuna tıkla
3. **Production mode** veya **Test mode** seç:
   - **Test mode** (Geliştirme için önerilen): Herkes okuyabilir/yazabilir
   - **Production mode**: Güvenlik kuralları gerekli

### Adım 3: Lokasyon Seç
1. Lokasyon olarak **europe-west** veya **eur3 (Europe)** seç
2. **"Enable"** butonuna tıkla

### Adım 4: Güvenlik Kurallarını Ayarla
Test mode seçtiyseniz otomatik olarak şu kurallar eklenecek:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 2, 1);
    }
  }
}
```

**ÖNERİLEN GÜVENLİK KURALLARI** (Production için):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false;
      
      match /vendors/{vendorId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
      
      match /invoices/{invoiceId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }
  }
}
```

### Adım 5: Uygulamayı Yeniden Çalıştır
```bash
flutter run
```

## 📊 Firestore Koleksiyon Yapısı

Veritabanı oluşturulduktan sonra otomatik olarak şu yapı oluşacak:

```
users/
  {userId}/
    - email
    - displayName
    - companyName
    - createdAt
    
    vendors/
      {vendorId}/
        - name
        - taxNumber
        - invoiceCount
        - totalAmount
    
    invoices/
      {invoiceId}/
        - vendorName (İş yeri adı)
        - invoiceDate (Tarih)
        - totalAmount (Tutar)
        - createdAt
```

## 🔍 Kontrol

Firestore'un çalıştığını kontrol etmek için:
1. Uygulamayı çalıştır
2. Giriş yap
3. Yeni fatura ekle
4. Firebase Console > Firestore Database'de veriyi gör

## ❓ Hala Hata Alıyorsanız

1. Firebase projenizin doğru olduğundan emin olun
2. `google-services.json` ve `GoogleService-Info.plist` dosyalarının güncel olduğunu kontrol edin
3. İnternet bağlantınızı kontrol edin
4. Uygulamayı tamamen kapatıp yeniden başlatın

---

**İletişim:** Sorun devam ederse proje ekibine ulaşın.
