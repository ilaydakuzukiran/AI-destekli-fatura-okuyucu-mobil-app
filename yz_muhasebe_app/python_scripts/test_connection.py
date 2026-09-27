# PC'de bu scripti çalıştır: python test_connection.py

import socket
import sys

def test_server():
    """8000 portunu dinleyip gelen bağlantıları test eder"""
    HOST = '0.0.0.0'
    PORT = 8000
    
    print("=" * 60)
    print("🔌 BAĞLANTI TEST SUNUCUSU")
    print("=" * 60)
    
    try:
        # Socket oluştur
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            # SO_REUSEADDR seçeneğini aktifleştir (port meşgulse yeniden kullan)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            
            # Bind et
            s.bind((HOST, PORT))
            print(f"✅ Port {PORT} başarıyla bağlandı!")
            
            # Dinlemeye başla
            s.listen(1)
            print(f"🎧 Port {PORT} dinleniyor...")
            print(f"📱 Mobil uygulamadan bağlantı bekleniyor...\n")
            
            # IP adresini göster
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            print(f"💻 PC IP Adresi: {local_ip}")
            print(f"📍 Port: {PORT}")
            print(f"📝 Mobil uygulamaya gir: {local_ip}\n")
            print("=" * 60)
            
            # Bağlantı bekle
            conn, addr = s.accept()
            with conn:
                print(f"\n✅ BAĞLANTI BAŞARILI!")
                print(f"📱 Mobil Cihaz: {addr[0]}:{addr[1]}")
                print(f"🔗 Bağlantı kuruldu!\n")
                
                # Veri al
                data = conn.recv(1024)
                if data:
                    print(f"📦 Alınan veri boyutu: {len(data)} byte")
                    print(f"📄 İlk 100 karakter: {data[:100]}")
                    print("\n🎉 TEST BAŞARILI! Bağlantı çalışıyor.")
                else:
                    print("⚠️ Veri alınamadı")
                    
    except PermissionError:
        print(f"❌ HATA: Port {PORT} için yönetici izni gerekiyor!")
        print("💡 Çözüm: Bu scripti yönetici olarak çalıştır")
    except OSError as e:
        if e.errno == 10048:  # Windows: Port already in use
            print(f"❌ HATA: Port {PORT} başka bir program tarafından kullanılıyor!")
            print(f"💡 Çözüm 1: excel_transfer_receiver.py çalışıyorsa kapat")
            print(f"💡 Çözüm 2: Komut: netstat -ano | findstr :{PORT}")
        else:
            print(f"❌ Socket Hatası: {e}")
    except Exception as e:
        print(f"❌ Beklenmeyen Hata: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("\n")
    test_server()
    print("\n" + "=" * 60)
    print("Test tamamlandı. Enter'a basarak çıkın...")
    input()
