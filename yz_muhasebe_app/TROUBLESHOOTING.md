# 🔧 EXCEL EXPORT BAĞLANTI SORUN GİDERME

## ❌ Sorun: "Bağlantı Kurulamadı"

### ✅ Adım 1: Port Kontrolü

**PC'de PowerShell/CMD aç ve çalıştır:**
```powershell
netstat -ano | findstr :8000
```

**Sonuç varsa:**
- Port 8000 meşgul! 
- Çözüm: Diğer programı kapat veya farklı port kullan

**Sonuç yoksa:**
- Port boş, Python sunucusu çalışmıyor

---

### ✅ Adım 2: Test Script Çalıştır

**PC'de:**
```powershell
cd "C:\Users\HP\Desktop\Bitirme Projesi\yz_muhasebe_app\python_scripts"
python test_connection.py
```

**Ekranda göreceksin:**
- PC IP adresi (örn: 192.168.1.6)
- Port: 8000
- "Mobil uygulamadan bağlantı bekleniyor..."

**Mobil uygulamada:**
- IP adresini gir
- Tarih seç
- "Veriyi PC'ye Aktar" butonuna bas

**Başarılı ise:** "BAĞLANTI BAŞARILI!" yazısı çıkacak
**Başarısız ise:** Adım 3'e geç

---

### ✅ Adım 3: IP Adresi Kontrolü

**PC'de IP adresini öğren:**
```powershell
ipconfig
```

**Wireless LAN adapter Wi-Fi** bölümünde:
```
IPv4 Address. . . . . . . . . . . : 192.168.1.6
```

Bu IP'yi mobil uygulamaya gir (son noktayı unutma!)

---

### ✅ Adım 4: WiFi Kontrolü

**Her iki cihaz da AYNI WiFi ağında olmalı:**

**PC'de:**
```powershell
netsh wlan show interfaces
```
"SSID" satırını kontrol et

**Mobil'de:**
- Ayarlar → WiFi → Bağlı ağ adı

**Farklı ağlarda mı?**
- Aynı WiFi'ye bağlan
- Mobil hotspot kullanma!

---

### ✅ Adım 5: Firewall Kontrolü

**Windows Firewall port 8000'i engelliyor olabilir:**

```powershell
# PowerShell'i YÖNETİCİ olarak aç, çalıştır:
New-NetFirewallRule -DisplayName "Python Port 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

---

### ✅ Adım 6: Python Sunucu Çalıştır

**Doğru komut:**
```powershell
cd "C:\Users\HP\Desktop\Bitirme Projesi\yz_muhasebe_app\python_scripts"
python excel_transfer_receiver.py
```

**Görmeli:**
```
Sunucu başlatıldı. Mobil bağlantı bekleniyor: Port 8000
```

**Hata: "Address already in use"**
- Port meşgul
- Adım 1'e dön

**Hata: "python komut bulunamadı"**
```powershell
python3 excel_transfer_receiver.py
# veya
py excel_transfer_receiver.py
```

---

### ✅ Adım 7: Flutter Debug Log Kontrol

**PC'de VS Code'da terminal çıktısına bak:**
```
🔌 Bağlantı denemesi: 192.168.1.6:8000 (Deneme: 0)
⏳ Socket.connect başlatılıyor...
```

**Başarılı bağlantı:**
```
✅ Bağlantı başarılı!
📤 JSON verisi gönderiliyor...
✅ Veri gönderimi tamamlandı
```

**Başarısız bağlantı:**
```
❌ SocketException: ...
```

---

## 🎯 Hızlı Kontrol Listesi

- [ ] PC ve mobil AYNI WiFi'de
- [ ] Port 8000 boş (`netstat -ano | findstr :8000`)
- [ ] Python sunucusu çalışıyor
- [ ] IP adresi doğru (ipconfig)
- [ ] Firewall izni var
- [ ] Tarih seçildi
- [ ] Firestore'da fatura var (16-10-2025 ile 17-10-2025 arası)

---

## 📞 Test Senaryosu

1. **PC:** `python test_connection.py` çalıştır
2. **Mobil:** IP gir, tarihleri seç, "Aktar" bas
3. **PC:** "BAĞLANTI BAŞARILI!" mesajını gör
4. **Eğer başarılı:** Sunucuyu kapat, `python excel_transfer_receiver.py` çalıştır
5. **Mobil:** Tekrar dene → Excel dosyası oluşmalı

---

## 🔍 Debug Komutu

**Eğer hala çalışmazsa, PC'de ping testi:**
```powershell
ping <MOBİL_CİHAZ_IP>
```

Mobil IP'yi öğrenmek için mobil uygulamada "Veri Aktarımı" ekranının üstünde gösteriliyor:
```
Mobil Cihaz IP'niz: 192.168.1.2
```

---

## ❗ Yaygın Hatalar

| Hata | Sebep | Çözüm |
|------|-------|-------|
| Connection refused | Python sunucu çalışmıyor | `python excel_transfer_receiver.py` |
| Connection timeout | Farklı WiFi ağları | Aynı ağa bağlan |
| Address in use | Port meşgul | `netstat` ile kontrol, kapat |
| No route to host | Firewall | Port 8000 iznini aç |

---

**Hala çalışmıyor mu?** Terminal çıktısını ve hata mesajını paylaş!
