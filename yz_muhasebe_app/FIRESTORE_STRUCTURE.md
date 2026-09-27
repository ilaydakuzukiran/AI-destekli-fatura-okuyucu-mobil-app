# Firestore Veri Yapısı ve Güvenlik Kuralları

## 📊 Koleksiyon Yapısı

### 1. Users Collection
```
users/
  {userId}/
    - email: string
    - displayName: string
    - phoneNumber: string
    - companyName: string
    - taxNumber: string
    - createdAt: timestamp
    - updatedAt: timestamp
    - isActive: boolean
    - role: string (user, admin, accountant)
```

### 2. Vendors Sub-Collection (Her kullanıcının kendi satıcıları)
```
users/
  {userId}/
    vendors/
      {vendorId}/
        - userId: string
        - name: string
        - taxNumber: string
        - taxOffice: string
        - address: string
        - city: string
        - country: string
        - phone: string
        - email: string
        - website: string
        - contactPerson: string
        - category: string (supplier, service, other)
        - isActive: boolean
        - createdAt: timestamp
        - updatedAt: timestamp
        - invoiceCount: number
        - totalAmount: number
```

### 3. Invoices Sub-Collection (Her kullanıcının kendi faturaları)
```
users/
  {userId}/
    invoices/
      {invoiceId}/
        - userId: string
        - vendorId: string
        - vendorName: string
        - invoiceNumber: string
        - invoiceDate: string (DD-MM-YYYY)
        - totalAmount: number
        - taxAmount: number
        - discountAmount: number
        - currency: string (TL, USD, EUR)
        - imageUrl: string
        - localImagePath: string
        - notes: string
        - status: string (pending, approved, rejected)
        - createdAt: timestamp
        - updatedAt: timestamp
        - items: array
            - description: string
            - quantity: number
            - unitPrice: number
            - totalPrice: number
            - taxRate: number
```

## 🔒 Firestore Security Rules

Aşağıdaki güvenlik kurallarını Firebase Console'da Firestore > Rules bölümüne ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Kullanıcı doğrulama fonksiyonu
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Kullanıcının kendi verisi mi kontrolü
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Kullanıcı sadece kendi profilini okuyabilir ve güncelleyebilir
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // Kullanıcı silme işlemi yasak
      
      // Vendors sub-collection
      match /vendors/{vendorId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
      
      // Invoices sub-collection
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

## 📝 Firestore İndeksler

Performans için gerekli indeksler:

### Invoices Collection İndeksleri
1. **Tarih Sorgulama:**
   - Collection: `users/{userId}/invoices`
   - Fields: `invoiceDate` (Ascending), `__name__` (Ascending)

2. **Satıcı Bazlı Sorgulama:**
   - Collection: `users/{userId}/invoices`
   - Fields: `vendorId` (Ascending), `createdAt` (Descending)

3. **Durum Bazlı Sorgulama:**
   - Collection: `users/{userId}/invoices`
   - Fields: `status` (Ascending), `createdAt` (Descending)

### Vendors Collection İndeksleri
1. **İsim Arama:**
   - Collection: `users/{userId}/vendors`
   - Fields: `name` (Ascending), `isActive` (Ascending)

2. **Kategori Filtreleme:**
   - Collection: `users/{userId}/vendors`
   - Fields: `category` (Ascending), `name` (Ascending)

## 🚀 Kullanım Örnekleri

### Yeni Kullanıcı Oluşturma
```dart
final user = UserModel(
  uid: firebaseUser.uid,
  email: firebaseUser.email!,
  displayName: 'John Doe',
  createdAt: DateTime.now(),
);
await firestoreService.createUser(user);
```

### Yeni Satıcı Ekleme
```dart
final vendor = Vendor(
  userId: currentUser.uid,
  name: 'ABC Ltd. Şti.',
  taxNumber: '1234567890',
  createdAt: DateTime.now(),
);
final vendorId = await firestoreService.createVendor(vendor);
```

### Yeni Fatura Oluşturma
```dart
final invoice = Invoice(
  userId: currentUser.uid,
  vendorId: selectedVendor.id!,
  vendorName: selectedVendor.name,
  invoiceNumber: 'INV-001',
  invoiceDate: '30-12-2025',
  totalAmount: 1500.00,
  createdAt: DateTime.now(),
);
final invoiceId = await firestoreService.createInvoice(invoice);
```

### Faturaları Listeleme (Stream)
```dart
StreamBuilder<List<Invoice>>(
  stream: firestoreService.getInvoices(currentUser.uid),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final invoices = snapshot.data!;
      return ListView.builder(...);
    }
    return CircularProgressIndicator();
  },
);
```

## 📈 Veri İlişkileri

```
User (1) ----< (N) Vendors
User (1) ----< (N) Invoices
Vendor (1) ----< (N) Invoices
```

- Bir kullanıcının birçok satıcısı olabilir
- Bir kullanıcının birçok faturası olabilir
- Bir satıcının birçok faturası olabilir
- Her fatura bir satıcıya referans verir (vendorId)

## 🔄 Veri Senkronizasyonu

- Fatura eklendiğinde/silindiğinde satıcı istatistikleri otomatik güncellenir
- `invoiceCount` ve `totalAmount` alanları her fatura işleminde güncellenir
- Gerçek zamanlı güncellemeler için Stream kullanılır

## 🎯 Best Practices

1. **Pagination:** Büyük listelerde pagination kullanın
2. **Caching:** Sık kullanılan verileri cache'leyin
3. **Batch Operations:** Toplu işlemler için batch kullanın
4. **Offline Support:** Firestore'un offline desteğinden yararlanın
5. **Error Handling:** Tüm Firestore işlemlerinde try-catch kullanın
