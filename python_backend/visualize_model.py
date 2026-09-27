from ultralytics import YOLO
import cv2
import os
import random
from pathlib import Path

def visualize_predictions():
    """Model performansını görselleştir"""
    
    # Model yükle
    print("Model yükleniyor...")
    model = YOLO("best_new.pt")
    
    # Val ve train klasörlerinden rastgele görseller seç
    val_images = list(Path("dataset/val/images").glob("*.jpg")) + list(Path("dataset/val/images").glob("*.png"))
    train_images = list(Path("dataset/train/images").glob("*.jpg")) + list(Path("dataset/train/images").glob("*.png"))
    
    # Her birinden 5'er tane seç
    val_samples = random.sample(val_images, min(5, len(val_images)))
    train_samples = random.sample(train_images, min(5, len(train_images)))
    
    output_dir = Path("visualization_results")
    output_dir.mkdir(exist_ok=True)
    
    print("\n" + "="*60)
    print("VALİDATION SETİ - Model Tahminleri")
    print("="*60)
    
    for i, img_path in enumerate(val_samples):
        print(f"\n[{i+1}/5] İşleniyor: {img_path.name}")
        
        # Tahmin yap
        results = model(str(img_path), conf=0.10)
        
        # Görsel üzerine çiz
        img = cv2.imread(str(img_path))
        
        # Label dosyasını oku (ground truth)
        label_path = str(img_path).replace('images', 'labels').replace('.jpg', '.txt').replace('.png', '.txt')
        
        print(f"   📦 Tespit edilen: {len(results[0].boxes)} box")
        
        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            label = model.names[cls_id]
            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            
            # Renk kodları
            colors = {'date': (255, 0, 0), 'price': (0, 255, 0), 'workplace': (0, 0, 255)}
            color = colors.get(label, (255, 255, 255))
            
            # Box çiz
            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            
            # Label + confidence yaz
            text = f"{label} {conf:.2f}"
            cv2.putText(img, text, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            
            print(f"      - {label}: {conf:.2%}")
        
        # Ground truth box'ları da çiz (sarı ile)
        if os.path.exists(label_path):
            with open(label_path, 'r') as f:
                lines = f.readlines()
                h, w = img.shape[:2]
                
                for line in lines:
                    parts = line.strip().split()
                    if len(parts) >= 5:
                        cls_id = int(parts[0])
                        x_center, y_center, width, height = map(float, parts[1:5])
                        
                        # YOLO format -> pixel
                        x1 = int((x_center - width/2) * w)
                        y1 = int((y_center - height/2) * h)
                        x2 = int((x_center + width/2) * w)
                        y2 = int((y_center + height/2) * h)
                        
                        # Sarı çizgi (ground truth)
                        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 255), 1)
        
        # Kaydet
        output_path = output_dir / f"val_{i+1}_{img_path.name}"
        cv2.imwrite(str(output_path), img)
        print(f"   ✅ Kaydedildi: {output_path}")
    
    print("\n" + "="*60)
    print("TRAİN SETİ - Model Tahminleri")
    print("="*60)
    
    for i, img_path in enumerate(train_samples):
        print(f"\n[{i+1}/5] İşleniyor: {img_path.name}")
        
        results = model(str(img_path), conf=0.10)
        img = cv2.imread(str(img_path))
        
        label_path = str(img_path).replace('images', 'labels').replace('.jpg', '.txt').replace('.png', '.txt')
        
        print(f"   📦 Tespit edilen: {len(results[0].boxes)} box")
        
        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            label = model.names[cls_id]
            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            
            colors = {'date': (255, 0, 0), 'price': (0, 255, 0), 'workplace': (0, 0, 255)}
            color = colors.get(label, (255, 255, 255))
            
            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            text = f"{label} {conf:.2f}"
            cv2.putText(img, text, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            
            print(f"      - {label}: {conf:.2%}")
        
        # Ground truth
        if os.path.exists(label_path):
            with open(label_path, 'r') as f:
                lines = f.readlines()
                h, w = img.shape[:2]
                
                for line in lines:
                    parts = line.strip().split()
                    if len(parts) >= 5:
                        cls_id = int(parts[0])
                        x_center, y_center, width, height = map(float, parts[1:5])
                        
                        x1 = int((x_center - width/2) * w)
                        y1 = int((y_center - height/2) * h)
                        x2 = int((x_center + width/2) * w)
                        y2 = int((y_center + height/2) * h)
                        
                        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 255), 1)
        
        output_path = output_dir / f"train_{i+1}_{img_path.name}"
        cv2.imwrite(str(output_path), img)
        print(f"   ✅ Kaydedildi: {output_path}")
    
    print("\n" + "="*60)
    print("✅ Görselleştirme Tamamlandı!")
    print(f"📁 Sonuçlar: {output_dir.absolute()}")
    print("="*60)
    print("\nRenk Kodları:")
    print("  🔵 Mavi   = workplace")
    print("  🟢 Yeşil  = price")
    print("  🔴 Kırmızı = date")
    print("  🟡 Sarı   = Ground Truth (doğru etiket)")
    

if __name__ == "__main__":
    visualize_predictions()
