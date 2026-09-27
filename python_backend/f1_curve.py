from ultralytics import YOLO
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import cv2
from tqdm import tqdm

def calculate_iou(box1, box2):
    """İki box arasındaki IoU (Intersection over Union) hesapla"""
    x1_min, y1_min, x1_max, y1_max = box1
    x2_min, y2_min, x2_max, y2_max = box2
    
    # Kesişim alanı
    inter_x_min = max(x1_min, x2_min)
    inter_y_min = max(y1_min, y2_min)
    inter_x_max = min(x1_max, x2_max)
    inter_y_max = min(y1_max, y2_max)
    
    if inter_x_max < inter_x_min or inter_y_max < inter_y_min:
        return 0.0
    
    inter_area = (inter_x_max - inter_x_min) * (inter_y_max - inter_y_min)
    
    # Birleşim alanı
    box1_area = (x1_max - x1_min) * (y1_max - y1_min)
    box2_area = (x2_max - x2_min) * (y2_max - y2_min)
    union_area = box1_area + box2_area - inter_area
    
    return inter_area / union_area if union_area > 0 else 0.0

def load_ground_truth_boxes(label_path, img_shape):
    """Ground truth box'ları yükle"""
    boxes = []
    if not Path(label_path).exists():
        return boxes
    
    h, w = img_shape[:2]
    
    with open(label_path, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 5:
                cls_id = int(parts[0])
                x_center, y_center, width, height = map(float, parts[1:5])
                
                # YOLO format -> pixel coordinates
                x1 = (x_center - width/2) * w
                y1 = (y_center - height/2) * h
                x2 = (x_center + width/2) * w
                y2 = (y_center + height/2) * h
                
                boxes.append({
                    'class': cls_id,
                    'bbox': [x1, y1, x2, y2]
                })
    
    return boxes

def calculate_metrics_at_confidence(model, val_images, confidence_threshold, iou_threshold=0.5):
    """Belirli bir confidence threshold'da precision, recall ve F1 hesapla"""
    true_positives = 0
    false_positives = 0
    false_negatives = 0
    
    for img_path in val_images:
        # Tahmin yap
        results = model(str(img_path), conf=confidence_threshold, verbose=False)
        
        # Ground truth box'ları yükle
        img = cv2.imread(str(img_path))
        label_path = str(img_path).replace('images', 'labels').replace('.jpg', '.txt').replace('.png', '.txt')
        gt_boxes = load_ground_truth_boxes(label_path, img.shape)
        
        # Prediction box'ları
        pred_boxes = []
        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(float, box.xyxy[0])
            pred_boxes.append({
                'class': cls_id,
                'bbox': [x1, y1, x2, y2],
                'conf': conf
            })
        
        # Her ground truth için eşleşme ara
        matched_gt = set()
        matched_pred = set()
        
        for i, gt in enumerate(gt_boxes):
            best_iou = 0
            best_pred_idx = -1
            
            for j, pred in enumerate(pred_boxes):
                if pred['class'] == gt['class'] and j not in matched_pred:
                    iou = calculate_iou(gt['bbox'], pred['bbox'])
                    if iou > best_iou:
                        best_iou = iou
                        best_pred_idx = j
            
            if best_iou >= iou_threshold:
                true_positives += 1
                matched_gt.add(i)
                matched_pred.add(best_pred_idx)
        
        # Eşleşmeyen tahminler = false positive
        false_positives += len(pred_boxes) - len(matched_pred)
        
        # Eşleşmeyen ground truth = false negative
        false_negatives += len(gt_boxes) - len(matched_gt)
    
    # Metrikleri hesapla
    precision = true_positives / (true_positives + false_positives) if (true_positives + false_positives) > 0 else 0
    recall = true_positives / (true_positives + false_negatives) if (true_positives + false_negatives) > 0 else 0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    
    return precision, recall, f1

def generate_f1_curve():
    """F1-Confidence eğrisini oluştur"""
    print("=" * 60)
    print("F1-SCORE EĞRİSİ OLUŞTURULUYOR")
    print("=" * 60)
    
    # Model yükle
    print("\n📦 Model yükleniyor...")
    model = YOLO("best_new.pt")
    print("✅ Model hazır!")
    
    # Validation görselleri yükle
    print("\n📁 Validation görselleri yükleniyor...")
    val_images = list(Path("dataset/val/images").glob("*.jpg")) + \
                 list(Path("dataset/val/images").glob("*.png"))
    print(f"✅ {len(val_images)} görsel bulundu")
    
    # Farklı confidence threshold değerleri
    confidence_thresholds = np.arange(0.05, 0.95, 0.05)
    
    precisions = []
    recalls = []
    f1_scores = []
    
    print("\n🔄 Metrikler hesaplanıyor...")
    for conf_threshold in tqdm(confidence_thresholds, desc="Confidence Thresholds"):
        precision, recall, f1 = calculate_metrics_at_confidence(
            model, val_images, conf_threshold
        )
        precisions.append(precision)
        recalls.append(recall)
        f1_scores.append(f1)
    
    # En iyi F1 skorunu bul
    best_f1_idx = np.argmax(f1_scores)
    best_f1 = f1_scores[best_f1_idx]
    best_conf = confidence_thresholds[best_f1_idx]
    best_precision = precisions[best_f1_idx]
    best_recall = recalls[best_f1_idx]
    
    print("\n" + "=" * 60)
    print("📊 SONUÇLAR")
    print("=" * 60)
    print(f"En İyi F1-Score: {best_f1:.4f}")
    print(f"Optimal Confidence Threshold: {best_conf:.2f}")
    print(f"Bu threshold'da:")
    print(f"  - Precision: {best_precision:.4f}")
    print(f"  - Recall: {best_recall:.4f}")
    print("=" * 60)
    
    # Grafikleri çiz
    plt.figure(figsize=(15, 5))
    
    # 1. F1-Confidence Eğrisi
    plt.subplot(1, 3, 1)
    plt.plot(confidence_thresholds, f1_scores, 'b-', linewidth=2, label='F1-Score')
    plt.scatter([best_conf], [best_f1], color='red', s=100, zorder=5, 
                label=f'En İyi: {best_f1:.4f} @ {best_conf:.2f}')
    plt.xlabel('Confidence Threshold', fontsize=12)
    plt.ylabel('F1-Score', fontsize=12)
    plt.title('F1-Score vs Confidence Threshold', fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.ylim([0, 1])
    
    # 2. Precision-Recall Eğrisi
    plt.subplot(1, 3, 2)
    plt.plot(confidence_thresholds, precisions, 'g-', linewidth=2, label='Precision')
    plt.plot(confidence_thresholds, recalls, 'r-', linewidth=2, label='Recall')
    plt.xlabel('Confidence Threshold', fontsize=12)
    plt.ylabel('Score', fontsize=12)
    plt.title('Precision & Recall vs Confidence', fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.ylim([0, 1])
    
    # 3. Precision-Recall Curve
    plt.subplot(1, 3, 3)
    plt.plot(recalls, precisions, 'purple', linewidth=2)
    plt.scatter([best_recall], [best_precision], color='red', s=100, zorder=5,
                label=f'En İyi F1: {best_f1:.4f}')
    plt.xlabel('Recall', fontsize=12)
    plt.ylabel('Precision', fontsize=12)
    plt.title('Precision-Recall Curve', fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.xlim([0, 1])
    plt.ylim([0, 1])
    
    plt.tight_layout()
    
    # Kaydet
    output_dir = Path("visualization_results")
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / "f1_confidence_curve.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"\n✅ Grafik kaydedildi: {output_path}")
    
    # Metrikleri CSV olarak kaydet
    csv_path = output_dir / "f1_metrics.csv"
    with open(csv_path, 'w') as f:
        f.write("Confidence,Precision,Recall,F1-Score\n")
        for conf, prec, rec, f1 in zip(confidence_thresholds, precisions, recalls, f1_scores):
            f.write(f"{conf:.2f},{prec:.4f},{rec:.4f},{f1:.4f}\n")
    print(f"✅ Metrikler kaydedildi: {csv_path}")
    
    plt.show()

if __name__ == "__main__":
    generate_f1_curve()
