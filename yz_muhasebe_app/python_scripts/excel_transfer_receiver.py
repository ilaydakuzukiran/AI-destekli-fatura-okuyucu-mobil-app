# python_scripts/excel_transfer_receiver.py

import socket
import json
import pandas as pd
from datetime import datetime

# --- Ayarlar ---
# Mobil uygulamada da aynı PORT numarasını kullanacağız
HOST = '0.0.0.0'  # Tüm ağ arayüzlerini dinle
PORT = 8000       # Kullanılacak port

def create_excel(invoice_data_list):
    """Gelen fatura verilerini Pandas kullanarak Excel'e dönüştürür."""
    if not invoice_data_list:
        print("Hata: Aktarılacak fatura verisi bulunmadı.")
        return False
        
    df = pd.DataFrame(invoice_data_list)
    
    # Muhasebe standardına uygun sütun sıralaması ve formatlama
    df = df[['faturaTarihi', 'saticiAdi', 'toplamTutar']]
    
    # Dosya adını oluşturma
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"Muhasebe_Aktarim_{timestamp}.xlsx"
    
    try:
        # to_excel ve openpyxl ile .xlsx formatında dışa aktarım
        df.to_excel(filename, index=False) 
        print(f"\n✅ BAŞARILI: Excel dosyası oluşturuldu: {filename}")
        print(f"Toplam {len(invoice_data_list)} fatura kaydedildi.")
        return True
    except Exception as e:
        print(f"Excel oluşturma hatası: {e}")
        return False


def start_server():
    """Mobil cihazdan gelen veriyi dinleyen Socket sunucusunu başlatır."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind((HOST, PORT))
            s.listen()
            print(f"🚀 Sunucu başlatıldı ve sürekli dinliyor: Port {PORT}")
            print(f"📱 Mobil uygulamadan bağlantılar bekleniyor...")
            print(f"⚠️  Durdurmak için: Ctrl+C\n")
            print("=" * 60)
            
            # Sürekli çalışma döngüsü
            while True:
                try:
                    conn, addr = s.accept()  # Mobil bağlantı bekleniyor
                    with conn:
                        print(f"\n✅ Bağlantı kabul edildi: {addr}")
                        
                        # Veriyi parçalar halinde almak için bir döngü
                        data_chunks = []
                        while True:
                            chunk = conn.recv(4096)
                            if not chunk:
                                break
                            data_chunks.append(chunk)

                        # Tüm parçaları birleştirip JSON olarak yükleme
                        full_data = b''.join(data_chunks)
                        
                        if not full_data:
                            print("❌ Hata: Mobil cihazdan boş veri alındı.")
                            continue

                        # Gelen verinin JSON listesi olduğunu varsayıyoruz
                        invoice_list = json.loads(full_data.decode('utf-8'))
                        
                        print(f"📦 Veri Aktarımı Tamamlandı. {len(invoice_list)} kayıt işleniyor...")
                        create_excel(invoice_list)
                        
                        print("\n" + "=" * 60)
                        print("🎧 Yeni bağlantı bekleniyor...")
                        
                except json.JSONDecodeError:
                    print("❌ Hata: Alınan veri geçerli bir JSON formatında değil.")
                    print("🎧 Yeni bağlantı bekleniyor...")
                except Exception as e:
                    print(f"❌ Bağlantı Hatası: {e}")
                    print("🎧 Yeni bağlantı bekleniyor...")
                    
        except socket.error as e:
            print(f"❌ Socket hatası (Port meşgul olabilir): {e}")
        except KeyboardInterrupt:
            print("\n\n⏹️  Sunucu durduruldu. Güle güle!")
        except Exception as e:
            print(f"❌ Genel Hata: {e}")

if __name__ == "__main__":
    start_server()