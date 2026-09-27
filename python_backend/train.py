from ultralytics import YOLO

if __name__ == '__main__':
    # 1. Modeli Yükle
    # En güncel sürüm: YOLO11 Nano (n) modeli.
    print("Model yükleniyor: yolo11n.pt...")
    model = YOLO("yolo11n.pt") 

    # 2. Eğitimi Başlat (Fiş/Belge OCR için özel augmentation)
    print("Eğitim başlıyor (Fiş OCR için optimize edilmiş augmentation)...")
    results = model.train(
        data="dataset/data.yaml",     # Hazırladığımız harita dosyası
        epochs=100,                    # Daha fazla epoch
        imgsz=640,                     # Resim boyutu
        batch=16,                      # Bilgisayarın kasarsa bu sayıyı 8 veya 4 yap
        name="fatura_modelim",         # Sonuçların kaydedileceği klasör adı
        device="cpu",                  # CPU kullan (CUDA yok)
        
        # FİŞ/BELGE OCR İÇİN ÖZEL AUGMENTATION
        # Metin okunabilirliğini koruyacak şekilde ayarlandı
        
        degrees=3.0,                   # Çok hafif rotasyon (±3°) - telefon çekimindeki doğal eğim
        translate=0.05,                # Minimal kaydırma (%5) - merkezden hafif kayma
        scale=0.15,                    # Minimal zoom (%15) - mesafe farkları
        shear=0.0,                     # Yamultma YOK - metinleri bozar
        perspective=0.0001,            # Çok minimal perspektif - telefon açısı
        
        flipud=0.0,                    # Dikey çevirme YOK - fişler baş aşağı olmaz
        fliplr=0.0,                    # Yatay çevirme YOK - sayılar ters okunur
        
        mosaic=0.0,                    # Mozaik YOK - farklı fişlerin metinleri karışır
        mixup=0.0,                     # Mixup YOK - metinler üst üste biner
        
        # IŞIK/RENK/GÖRÜNTÜ KALİTESİ (ÖNEMLİ!)
        # Farklı telefon, ışık ve çekim koşullarını simüle eder
        hsv_h=0.01,                    # Minimal renk tonu değişimi
        hsv_s=0.5,                     # Orta seviye doygunluk - farklı telefon kameraları
        hsv_v=0.5,                     # Orta seviye parlaklık - farklı ışık koşulları
        
        auto_augment='randaugment',    # RandAugment - belge işleme için optimize
        erasing=0.2,                   # %20 random erasing - gölge/yansıma simülasyonu
        
        # EĞİTİM PARAMETRELERİ
        patience=30,                   # 30 epoch iyileşme yoksa dur
        save_period=10,                # Her 10 epoch'ta kaydet
        cache=True,                    # Veriyi RAM'de cache'le (hızlandırır)
        optimizer='AdamW',             # AdamW optimizer
        lr0=0.01,                      # Başlangıç learning rate
        lrf=0.01,                      # Final learning rate
        cos_lr=True,                   # Cosine learning rate scheduler
        close_mosaic=20,               # Son 20 epoch mosaic kapat (zaten 0)
    )
    
    print("Eğitim tamamlandı! Sonuçlar 'runs/detect/fatura_modelim' klasöründe.")